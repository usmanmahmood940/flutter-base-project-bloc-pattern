# Flutter Clean Architecture with BLoC Pattern

A comprehensive Flutter application demonstrating Clean Architecture principles with BLoC state management, dependency injection, and modern Flutter development practices.

## 🏗️ Architecture Overview

This project implements **Clean Architecture** with three distinct layers, ensuring separation of concerns and maintainability:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │    BLoC     │ │   Widgets   │ │   Screens   │           │
│  │   Cubits    │ │             │ │             │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │  Use Cases  │ │Repository   │ │  Entities   │           │
│  │             │ │Interfaces   │ │             │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │Repository   │ │ Data        │ │   Models    │           │
│  │Implement.   │ │ Sources     │ │             │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
lib/
├── main.dart                 # Application entry point
├── injection.dart            # Dependency injection setup
└── src/
    ├── comman/               # Shared utilities and constants
    │   ├── api.dart          # API endpoints
    │   ├── colors.dart       # Color definitions
    │   ├── constant.dart     # App constants
    │   ├── enum.dart         # Enums
    │   ├── exception.dart    # Custom exceptions
    │   ├── failure.dart      # Failure classes
    │   ├── images.dart       # Image assets
    │   ├── routes.dart       # Route definitions
    │   ├── screens.dart      # Screen dimensions
    │   ├── themes.dart       # App themes
    │   └── toast.dart        # Toast utilities
    │
    ├── data/                 # Data Layer
    │   ├── datasource/       # Data sources (API, Local)
    │   │   └── authentication_remote_data_source.dart
    │   └── repository/       # Repository implementations
    │       └── authentication_repository_impl.dart
    │
    ├── domain/               # Domain Layer (Business Logic)
    │   ├── repositories/     # Repository interfaces
    │   │   └── autentication_repository.dart
    │   └── usecase/          # Use cases
    │       └── login.dart
    │
    ├── presentation/         # Presentation Layer (UI)
    │   ├── bloc/            # BLoC state management
    │   │   ├── authenticator_watcher/
    │   │   └── sign_in_form/
    │   ├── cubit/           # Cubit state management
    │   │   └── theme/
    │   ├── page/            # Screen implementations
    │   │   ├── auth/
    │   │   ├── dashboard/
    │   │   ├── error/
    │   │   └── splash/
    │   └── widget/          # Reusable UI components
    │
    └── utilities/           # Helper utilities
        ├── app_bloc_observer.dart
        ├── debouncer.dart
        ├── extensions/
        ├── go_router_init.dart
        └── logger.dart
```

## 🔄 Data Flow Architecture

### 1. **User Interaction Flow**

```
User Input → Widget → BLoC Event → Use Case → Repository → Data Source → API/Local Storage
     ↑                                                                              ↓
     └─────────────── BLoC State ← Widget ← UI Update ←────────────────────────────┘
```

### 2. **Authentication Flow Example**

Let's trace the complete authentication flow:

#### **Step 1: User Input (Presentation Layer)**
```dart
// User types email/password in SignInPage
CustomTextFormField(
  onChanged: (v) {
    context.read<SignInFormBloc>().add(SignInFormEvent.emailOnChanged(v));
  },
)
```

#### **Step 2: BLoC Event Handling**
```dart
// SignInFormBloc processes the event
on<SignInFormEvent>(
  (event, emit) async {
    await event.map(
      emailOnChanged: (event) {
        emit(state.copyWith(email: event.email, state: RequestState.empty));
      },
      signInWithEmail: (_) async {
        emit(state.copyWith(state: RequestState.loading));
        final result = await _signInWithEmail.execute(state.email, state.password);
        // Handle result...
      },
    );
  },
)
```

#### **Step 3: Use Case Execution (Domain Layer)**
```dart
// SignIn use case
class SignIn {
  Future<Either<Failure, void>> execute(String email, String password) async {
    return await _repository.login(email, password);
  }
}
```

#### **Step 4: Repository Implementation (Data Layer)**
```dart
// AuthenticationRepositoryImpl
Future<Either<Failure, void>> login(String email, String password) async {
  try {
    final result = await dataSource.login(email, password);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}
```

#### **Step 5: Data Source (API Call)**
```dart
// AuthenticationRemoteDataSourceImpl
Future<void> login(String email, String password) async {
  final response = await dio.post(API.LOGIN, data: {
    'email': email,
    'password': password,
  });
  final token = response.data['token'].toString();
  await prefs.setString(ACCESS_TOKEN, token);
}
```

#### **Step 6: State Update & UI Refresh**
```dart
// BLoC emits new state
result.fold(
  (f) => emit(state.copyWith(state: RequestState.error, message: f.message)),
  (_) => emit(state.copyWith(state: RequestState.loaded))
);

// Widget rebuilds with new state
BlocBuilder<SignInFormBloc, SignInFormState>(
  builder: (context, state) {
    // UI updates based on state
  },
)
```

## 🛠️ Key Components Explained

### **1. Dependency Injection (`injection.dart`)**

Uses **GetIt** for service locator pattern:

```dart
final locator = GetIt.instance;

void init() {
  // Data sources
  locator.registerLazySingleton<AuthenticationRemoteDataSource>(
    () => AuthenticationRemoteDataSourceImpl(),
  );

  // Repositories
  locator.registerLazySingleton<AuthenticationRepository>(
    () => AuthenticationRepositoryImpl(locator()),
  );

  // Use cases
  locator.registerLazySingleton(() => SignIn(locator()));

  // BLoCs
  locator.registerLazySingleton(() => SignInFormBloc(locator()));
}
```

### **2. BLoC State Management**

**Event-Driven Architecture:**
- Events represent user actions
- States represent UI conditions
- BLoC processes events and emits states

```dart
// Events
abstract class SignInFormEvent with _$SignInFormEvent {
  const factory SignInFormEvent.emailOnChanged(String email) = _EmailOnChanged;
  const factory SignInFormEvent.passwordOnChanged(String password) = _PasswordOnChanged;
  const factory SignInFormEvent.signInWithEmail() = _SignInWithEmail;
}

// States
abstract class SignInFormState with _$SignInFormState {
  const factory SignInFormState({
    required String email,
    required String password,
    required RequestState state,
    String? message,
  }) = _SignInFormState;
}
```

### **3. Error Handling with Functional Programming**

Uses **dartz** package for functional error handling:

```dart
// Either<Failure, Success> pattern
Future<Either<Failure, void>> login(String email, String password) async {
  try {
    final result = await dataSource.login(email, password);
    return Right(result); // Success
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message)); // Error
  }
}
```

### **4. Navigation with GoRouter**

Declarative routing with centralized route management:

```dart
GoRouter routerinit = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      name: AppRoutes.LOGIN_ROUTE_NAME,
      path: AppRoutes.LOGIN_ROUTE_PATH,
      builder: (context, state) => const SignInPage(),
    ),
    // More routes...
  ],
);
```

## 🎯 Benefits of This Architecture

### **1. Separation of Concerns**
- **Presentation**: UI logic and state management
- **Domain**: Business logic and rules
- **Data**: Data access and external services

### **2. Testability**
- Each layer can be tested independently
- Use cases contain pure business logic
- Repository pattern enables easy mocking

### **3. Maintainability**
- Clear dependencies between layers
- Single responsibility principle
- Easy to modify without affecting other layers

### **4. Scalability**
- Easy to add new features
- Consistent patterns across the app
- Modular architecture supports team development

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Menu-Scanner-Flutter
   ```

2. **Install dependencies**
   ```bash
    flutter pub get
   ```

3. **Generate code** (for Freezed)
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 📱 Features Implemented

- ✅ **Authentication System** (Login/Signup)
- ✅ **State Management** (BLoC/Cubit)
- ✅ **Navigation** (GoRouter)
- ✅ **Theme Support** (Light/Dark)
- ✅ **Error Handling** (Functional programming)
- ✅ **Dependency Injection** (GetIt)
- ✅ **Code Generation** (Freezed)
- ✅ **Logging** (Structured logging)
- ✅ **Form Validation**
- ✅ **Loading States**

## 🧪 Testing

The project includes testing setup with:
- `bloc_test` for BLoC testing
- `mocktail` for mocking
- `flutter_test` for widget testing

## 📚 Dependencies

### **Core Dependencies**
- `flutter_bloc` - State management
- `get_it` - Dependency injection
- `freezed` - Code generation
- `dio` - HTTP client
- `go_router` - Navigation
- `dartz` - Functional programming
- `shared_preferences` - Local storage

### **UI Dependencies**
- `google_fonts` - Typography
- `flutter_spinkit` - Loading indicators
- `font_awesome_flutter` - Icons
- `fluttertoast` - Toast messages

### **Development Dependencies**
- `very_good_analysis` - Linting
- `build_runner` - Code generation
- `bloc_test` - BLoC testing
- `mocktail` - Mocking

## 🔧 Configuration

### **Environment Setup**
- Flutter SDK: `>=3.0.6 <4.0.0`
- Dart SDK: Compatible with Flutter version

### **Code Generation**
Run this command whenever you modify Freezed classes:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

---

**Happy Coding! 🚀**
