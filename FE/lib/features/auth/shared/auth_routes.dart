String landingPathForRole(String? role) {
  return switch (role) {
    'STUDENT' => '/home/student',
    'ADMIN'   => '/home/admin',
    'STAFF'   => '/home/staff',
    'MANAGER' => '/home/manager',
    _         => '/map',
  };
}
