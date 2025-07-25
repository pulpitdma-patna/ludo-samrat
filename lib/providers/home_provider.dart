import 'package:flutter/material.dart';
import 'package:frontend/services/home_api.dart';
import 'package:frontend/services/profile_api.dart';

class HomeProvider extends ChangeNotifier {
  final HomeApi api;
  HomeProvider({HomeApi? api}) : api = api ?? HomeApi() {
    // load();
  }

  List<dynamic> _bannerList = [];
  bool _loading = false;

  List<dynamic> get bannerList => _bannerList;
  bool get isLoading => _loading;


  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _bannerList = await api.getBanner();
    ProfileApi().getProfile();
    _loading = false;
    notifyListeners();
  }

}