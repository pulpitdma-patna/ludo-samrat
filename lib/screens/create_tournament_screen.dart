import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/theme.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/app_scaffold.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;

  void _create() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name required')),
      );
      return;
    }
    setState(() { _loading = true; });
    await context.read<TournamentProvider>().create({'name': _nameController.text});
    setState(() { _loading = false; });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
              'Create Tournament',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: AppTextStyles.headingSmall.fontSize!.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed:
                        _nameController.text.isNotEmpty ? _create : null,
                    child: const Text('Create'),
                  ),
          ],
        ),
      ),
    );
  }
}
