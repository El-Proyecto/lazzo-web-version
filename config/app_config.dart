class AppConfig {
  static const invitesBaseUrl = String.fromEnvironment(
    'INVITES_BASE_URL',
    defaultValue: 'https://getlazzo.com',
  );
}
