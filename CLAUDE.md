# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Machine Manager App** is a Flutter-based industrial machine management and ticketing system with real-time chat functionality. It uses Supabase for backend services (authentication, database, real-time subscriptions) and implements a gamified point system to encourage ticket resolution.

## Development Commands

### Running the Application
```bash
flutter run
```

### Dependencies
```bash
flutter pub get              # Install dependencies
flutter pub upgrade          # Upgrade dependencies
```

### Build Commands
```bash
flutter build apk            # Build Android APK
flutter build ios            # Build iOS (macOS only)
flutter build web            # Build web version
flutter build windows        # Build Windows executable
```

### Code Quality
```bash
flutter analyze              # Run static analysis
flutter test                 # Run unit tests (if available)
```

### Cleaning Build Artifacts
```bash
flutter clean                # Clean build cache
flutter pub get              # Reinstall after clean
```

## Architecture Overview

### State Management
- **Provider pattern** for global state (auth, tickets)
- Two main providers:
  - `AuthProvider` (lib/providers/auth_provider.dart:6): Manages authentication state, user profiles, and role-based permissions
  - `TicketProvider` (lib/providers/ticket_provider.dart:8): Manages tickets, machines, filtering, and ticket operations

### Backend Integration
- **SupabaseService** (lib/services/supabase_service.dart:9): Centralized service layer for all Supabase operations
  - Authentication (sign up, sign in, sign out, password reset)
  - Ticket CRUD operations with foreign key relationships
  - Real-time chat messages
  - User profiles with leaderboard functionality
  - Machine management
  - Todo items for tickets
  - Real-time subscriptions via Supabase streams

### Key Services
1. **TicketExpirationService** (lib/services/ticket_expiration_service.dart:7): Background service that runs every minute to:
   - Auto-close tickets after 3 days (default expiration)
   - Send warnings 24 hours before expiry
   - Handle ticket extension requests
   - Uses `flutter_local_notifications` for notifications

2. **MachineSeedService** (lib/services/machine_seed_service.dart): Seeds initial machine data on first run

### Data Models
All models located in `lib/models/`:
- **Ticket**: Core entity with status (open/in_progress/resolved/closed), priority, expiration tracking, and related user/machine objects
- **UserProfile**: User data with role (admin/manager/technician/member), points, tickets solved, and average rating
- **Machine**: Industrial machine entities with categories (Alpha/Beta/Gamma/Delta/Packaging/QC)
- **ChatMessage**: Real-time messages associated with tickets
- **TodoItem**: Action items within tickets

### UI Structure
- **Dashboard Screen** (lib/screens/dashboard/dashboard_screen.dart): Main hub with room selection, ticket management, and problem submission forms
- **Chat Screen** (lib/screens/chat/chat_screen.dart): Real-time chat interface for ticket discussions
- **Login Screen** (lib/screens/auth/login_screen.dart): Authentication UI

### Configuration
- **AppConstants** (lib/config/constants.dart): Centralized constants including:
  - Supabase credentials
  - Default ticket expiration (3 days)
  - Points system configuration (10 base points + priority/rating bonuses)
  - Machine categories matching HTML demo structure
  - Problem types and priorities

- **AppColors** (lib/config/colors.dart): Design system with teal primary color theme

### Custom Widgets
Located in `lib/widgets/`:
- `EnhancedTicketCard`: Ticket cards with countdown timers, chat/close buttons
- `AnimatedFormField`: Form inputs with animations
- `AnimatedButton`: Interactive buttons with animations
- `SkeletonLoader`: Loading states
- `ErrorState`: Error display component
- `ResponsiveLayout`: Responsive breakpoint helper

## Supabase Database Schema

### Tables Overview
The app expects these Supabase tables with foreign key constraints:

**profiles**: User profiles with columns id, email, full_name, role, avatar_url, points, tickets_solved, average_rating

**machines**: Industrial machines with id, name, category, status, location

**tickets**: Core entity with:
- Foreign keys: creator_id → profiles, assignee_id → profiles, resolver_id → profiles, machine_id → machines
- Constraint names: fk_tickets_creator, fk_tickets_assignee, fk_tickets_resolver, fk_tickets_machine
- Status lifecycle: open → in_progress → resolved/closed
- Auto-expiration fields: expires_at (defaults to 3 days), auto_close_warned (boolean)

**chat_messages**: Real-time messages with foreign key sender_id → profiles (constraint: chat_messages_sender_id_fkey)

**ticket_todos**: Checklist items with foreign keys created_by/completed_by → profiles

### Supabase Client Access
All database operations go through `SupabaseService.client` which provides:
- Authenticated queries using row-level security (RLS)
- Real-time subscriptions via `.stream(primaryKey: ['id'])`
- Foreign key joins using PostgREST syntax (e.g., `creator:profiles!fk_tickets_creator(*)`)

## Important Implementation Notes

### Ticket Creation Flow
When creating tickets (lib/providers/ticket_provider.dart:126):
1. Validate machine exists in local cache first
2. Use SupabaseService.createTicket with machine_id validation
3. Automatic expiration timestamp (now + 3 days)
4. Ticket appears at top of list (insert at index 0)

### Foreign Key Relationships
The app relies heavily on Supabase foreign key joins. When querying tickets:
- Use PostgREST relationship syntax: `creator:profiles!fk_tickets_creator(*)`
- Handle nullable relations (assignee, resolver may be null for new tickets)
- For simplified queries without joins, set relations to null manually (see lib/services/supabase_service.dart:196)

### Real-time Features
- Chat messages use Supabase real-time subscriptions
- Ticket updates propagate via `.stream()` subscriptions
- Background expiration service runs independently every 1 minute

### Authentication State
- AuthWrapper component (lib/main.dart:73) handles routing based on auth state
- AuthProvider automatically creates profiles for new users if missing
- User roles affect UI permissions (admin/manager/technician/member)

## Common Patterns

### Error Handling
All service methods use try-catch with rethrow pattern. Providers catch errors and store in `_errorMessage` for UI display.

### Loading States
Providers use `_isLoading` boolean flag and call `notifyListeners()` before/after async operations.

### Filtering & Search
TicketProvider provides:
- Pre-filtered getters: `openTickets`, `myTickets`, `expiringTickets`, etc.
- Filter setters for status/priority/problemType/machine
- Search function across title/description/machine name/creator name

### Points Calculation
Points awarded when resolving tickets (lib/models/ticket.dart:282):
- Base: 10 points
- Priority bonus: critical +15, high +10, medium +5, low +0
- Quick response bonus: +5 if resolved within 4 hours
- Rating bonus: rating × 2

## Development Workflow

1. **Supabase Setup**: Ensure credentials in lib/config/constants.dart match your Supabase project
2. **Initial Run**: App automatically seeds machines on first launch (main.dart:36)
3. **Testing**: TestTicketCreation utility runs on startup (main.dart:44)
4. **Hot Reload**: Flutter supports hot reload during development (Cmd+\ or Ctrl+\)

## Key Dependencies
- `supabase_flutter: ^2.8.0` - Backend services
- `provider: ^6.1.2` - State management
- `go_router: ^14.6.1` - Navigation (configured but not fully utilized)
- `flutter_local_notifications: ^18.0.1` - Expiration warnings
- `cached_network_image: ^3.4.1` - Avatar images
- `fl_chart: ^0.69.2` - Analytics charts
- `intl: ^0.19.0` - Date formatting
