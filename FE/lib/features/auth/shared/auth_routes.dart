String landingPathForRole(String? role) {
  return switch (role) {
    'STUDENT' => '/student/my-registrations',
    'ADMIN' => '/admin/users',
    'STAFF' || 'MANAGER' => '/campaigns',
    _ => '/map',
  };
}
