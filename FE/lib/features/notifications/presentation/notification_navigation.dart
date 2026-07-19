String notificationDestination(Map<String, dynamic> data) {
  final type = data['type']?.toString().toLowerCase() ?? '';
  final eventId = data['eventId']?.toString() ?? '';
  final campaignId = data['campaignId']?.toString() ?? '';

  if (eventId.isNotEmpty && int.tryParse(eventId) != null) {
    return '/events/$eventId';
  }
  if (type.startsWith('registration_')) {
    return '/student/my-registrations';
  }
  if (campaignId.isNotEmpty && int.tryParse(campaignId) != null) {
    return '/campaigns/$campaignId/dashboard';
  }
  if (type == 'account_deactivated') return '/login';
  return '/notifications';
}
