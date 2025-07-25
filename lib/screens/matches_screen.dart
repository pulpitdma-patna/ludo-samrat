import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/theme.dart';
import '../services/profile_api.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/app_scaffold.dart';

class MatchesScreen extends StatefulWidget {
  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<dynamic> _matches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() => _isLoading = true);
    final result = await ProfileApi().matchHistory();
    if (result.isSuccess) {
      setState(() => _matches = result.data ?? []);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    }
    if (mounted) setState(() => _isLoading = false);
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
              'Matches',
              style: AppTextStyles.poppinsSemiBold.copyWith(
                fontSize: 18.sp,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: _matches.length,
            itemBuilder: (context, index) {
              final m = _matches[index];
              return ListTile(
                title: Text('Match ${m['match_id']}'),
                subtitle: Text(m['result']),
              );
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
