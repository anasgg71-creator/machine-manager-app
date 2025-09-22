class AppConstants {
  // Supabase credentials
  static const String supabaseUrl = 'https://xsrvoyjdrylusvmdwppl.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzcnZveWpkcnlsdXN2bWR3cHBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NTQwNTAsImV4cCI6MjA3NDEzMDA1MH0.uzI9As8aqUenZvMIk9U1XwAWrOxF_jl3intDHJPSve0';

  // App Info
  static const String appName = 'Machine Manager';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const Duration timeoutDuration = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String dashboardRoute = '/dashboard';
  static const String ticketsRoute = '/tickets';
  static const String teamRoute = '/team';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String createTicketRoute = '/create-ticket';
  static const String ticketDetailRoute = '/ticket';
  static const String chatRoute = '/chat';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Default Values
  static const int defaultTicketExpireDays = 3;
  static const int pointsPerTicketSolved = 10;
  static const int pointsPerStarRating = 2;
  static const int quickResponseBonusPoints = 5;

  // Priority levels
  static const List<String> ticketPriorities = [
    'low',
    'medium',
    'high',
    'critical'
  ];

  // Problem types
  static const List<String> problemTypes = [
    'mechanical',
    'electrical',
    'software',
    'maintenance',
    'general'
  ];

  // Ticket statuses
  static const List<String> ticketStatuses = [
    'open',
    'in_progress',
    'resolved',
    'closed'
  ];

  // User roles
  static const List<String> userRoles = [
    'admin',
    'manager',
    'technician',
    'member'
  ];

  // File upload limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp'
  ];

  // Notification types
  static const String notificationTicketCreated = 'ticket_created';
  static const String notificationTicketAssigned = 'ticket_assigned';
  static const String notificationTicketResolved = 'ticket_resolved';
  static const String notificationNewMessage = 'message';
  static const String notificationSystem = 'system';

  // Cache keys
  static const String cacheKeyUserProfile = 'user_profile';
  static const String cacheKeyTickets = 'tickets';
  static const String cacheKeyLeaderboard = 'leaderboard';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

class AppStrings {
  // General
  static const String appName = 'Machine Manager';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String info = 'Info';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String remove = 'Remove';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';

  // Authentication
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';

  // Navigation
  static const String dashboard = 'Dashboard';
  static const String tickets = 'Tickets';
  static const String activeIssues = 'Active Issues';
  static const String history = 'History';
  static const String team = 'Team';
  static const String leaderboard = 'Leaderboard';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';

  // Tickets
  static const String createTicket = 'Create Ticket';
  static const String ticketTitle = 'Title';
  static const String ticketDescription = 'Description';
  static const String machine = 'Machine';
  static const String problemType = 'Problem Type';
  static const String priority = 'Priority';
  static const String status = 'Status';
  static const String assignedTo = 'Assigned To';
  static const String createdBy = 'Created By';
  static const String resolvedBy = 'Resolved By';
  static const String createdAt = 'Created';
  static const String resolvedAt = 'Resolved';
  static const String expiresAt = 'Expires';
  static const String resolution = 'Resolution';
  static const String rating = 'Rating';

  // Chat
  static const String chat = 'Chat';
  static const String typeMessage = 'Type a message...';
  static const String sendMessage = 'Send';
  static const String attachFile = 'Attach File';
  static const String actionsTried = 'Actions Tried';
  static const String addAction = 'Add Action';
  static const String markAsTried = 'Mark as Tried';

  // Team
  static const String teamMembers = 'Team Members';
  static const String points = 'Points';
  static const String ticketsSolved = 'Tickets Solved';
  static const String averageRating = 'Average Rating';
  static const String rank = 'Rank';
  static const String achievements = 'Achievements';

  // Errors
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please login again.';
  static const String errorPermission = 'You do not have permission to perform this action.';
  static const String errorValidation = 'Please check your input and try again.';
  static const String errorFileSize = 'File size exceeds the maximum limit.';
  static const String errorFileType = 'File type is not supported.';

  // Success messages
  static const String successTicketCreated = 'Ticket created successfully!';
  static const String successTicketUpdated = 'Ticket updated successfully!';
  static const String successTicketResolved = 'Ticket resolved successfully!';
  static const String successMessageSent = 'Message sent successfully!';
  static const String successProfileUpdated = 'Profile updated successfully!';
}