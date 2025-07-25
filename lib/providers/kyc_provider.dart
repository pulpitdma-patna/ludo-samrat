import 'package:flutter/material.dart';
import 'package:frontend/services/app_preferences.dart';
import 'package:frontend/services/kyc_api.dart';
import 'package:image_picker/image_picker.dart';

class KycProvider extends ChangeNotifier{

  final KycApi api;
  KycProvider({KycApi? api}) : api = api ?? KycApi(){
    //
  }

  bool _loading = false;
  bool get isLoading => _loading;

  bool _isSubmit = false;
  bool get isSubmit => _isSubmit;

  String _kycStatus = "";
  String get kycStatus => _kycStatus;

  int _userId = 0;

  XFile? _document;
  XFile? get document => _document;

  void setDocument(XFile? file) {
    _document = file;
    notifyListeners();
  }

  TextEditingController docController = TextEditingController();


  Future<void> load() async {
    _userId = await AppPreferences().getUserId();
    checkKycStatus();
  }

  Future<void> checkKycStatus() async {
    _loading = true;
    notifyListeners();
    final res = await KycApi().status(_userId);
    if (res.isSuccess && res.data != null) {
      _kycStatus = res.data!['status'] as String;
      docController.text = res.data!['document_url'] ??'';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> submit(context) async {
    if (_document == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Upload a document')));
      return;
    }
    try{
      _isSubmit = true;
      notifyListeners();
      final res = await KycApi().submitFile(_document!);
      if (res.isSuccess) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Submitted')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.error ?? 'Error')));
      }
      _isSubmit = false;
      notifyListeners();
    }catch(e){
      _isSubmit = false;
      notifyListeners();
    }
  }




}