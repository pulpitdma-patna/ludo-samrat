import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/theme.dart';
import '../services/profile_api.dart';
import '../services/tutorial_storage.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/app_scaffold.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _idController = TextEditingController();
  List<dynamic> _friends = [];
  final Set<int> _selected = {};
  bool _showTutorial = false;
  bool _isLoading = false;
  bool _inputValid = false;

  void _onIdChanged() {
    setState(() {
      _inputValid = int.tryParse(_idController.text) != null;
    });
  }

  void _checkTutorial() async {
    final seen = await TutorialStorage.hasSeenFeature('friends');
    if (!seen) setState(() => _showTutorial = true);
  }

  void _dismissTutorial() async {
    await TutorialStorage.setFeatureSeen('friends');
    setState(() => _showTutorial = false);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _checkTutorial();
    _onIdChanged();
  }

  void _load() async {
    setState(() => _isLoading = true);
    final result = await ProfileApi().listFriends();
    if (result.isSuccess) {
      setState(() => _friends = result.data ?? []);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _add() async {
    final id = int.tryParse(_idController.text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid ID')),
      );
      return;
    }
    final result = await ProfileApi().addFriend(id);
    if (result.isSuccess) {
      _idController.clear();
      _onIdChanged();
      _load();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    }
  }

  void _remove(int id) async {
    final result = await ProfileApi().removeFriend(id);
    if (result.isSuccess) {
      _load();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    }
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  // void _createGame() async {
  //   if (_selected.isEmpty) return;
  //   setState(() => _creatingGame = true);
  //   final result = await GameApi().createGame(_selected.length + 1);
  //   setState(() => _creatingGame = false);
  //   if (result.isSuccess && result.data != null) {
  //     final link = '/game/${result.data}/join';
  //     await Clipboard.setData(ClipboardData(text: link));
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Game created. Link copied: $link')),
  //     );
  //     _selected.clear();
  //   } else {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text(result.error ?? 'Error')));
  //   }
  // }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: GradientAppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 28.w,
            height: 28.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Center(
              child: Icon(
                Icons.arrow_back,
                size: 22.h,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              'Friends',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        decoration: InputDecoration(labelText: 'Friend ID'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onIdChanged(),
                      ),
                    ),
                    ElevatedButton(
                        onPressed: _inputValid ? _add : null,
                        child: const Text('Add')),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final f = _friends[index];
                    final id = f['id'] as int;
                    return ListTile(
                      leading: Checkbox(
                        value: _selected.contains(id),
                        onChanged: (_) => _toggle(id),
                      ),
                      title: Text(f['phone_number'] ?? id.toString()),
                      trailing: IconButton(
                        tooltip: 'Remove friend',
                        icon: const Icon(Icons.delete, semanticLabel: 'remove friend'),
                        onPressed: () => _remove(id),
                      ),
                    );
                  },
                ),
              ),
//               if (_selected.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: ElevatedButton(
//                     onPressed: _creatingGame ? null : _createGame,
//                     child: _creatingGame
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                         : Text('Create Game with ${_selected.length}'),
//                   ),
//                 )
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_showTutorial)
            TutorialOverlay(
              type: TutorialType.friends,
              onDismiss: _dismissTutorial,
            ),
        ],
      ),
    );
  }
}
