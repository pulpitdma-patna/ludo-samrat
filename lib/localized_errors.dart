const Map<String, String> _messages = {
  'network_error': 'Unable to connect. Check your internet connection.',
  '400': 'Invalid request.',
  '401': 'Unauthorized request.',
  '403': 'Permission denied.',
  '404': 'Not found.',
  '500': 'Server error. Please try again later.',
};

String localizeError(String? code, String message) {
  if (code == '403' && message == 'KYC not completed') {
    return message;
  }
  if (code != null && _messages.containsKey(code)) {
    return _messages[code]!;
  }
  return message;
}
