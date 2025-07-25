String? validatePhone(String value) {
  if (value.isEmpty) {
    return "This field is required";
  } else if (!RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\/0-9]+$')
      .hasMatch(value)) {
    return "Please Enter Valid Phone No.";
  }
  return null;
}

String? validatePassword(String value) {
  if (value.isEmpty) {
    return "This field is required";
  } else if (value.length < 6) {
    return "Password must be at least 6 characters";
  }
  return null;
}

String? validateOtp(String value) {
  if (value.isEmpty) {
    return "This field is required";
  } else if (value.length != 6) {
    return "Invalid OTP";
  }
  return null;
}
