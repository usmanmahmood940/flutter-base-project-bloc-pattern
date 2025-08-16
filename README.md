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
    │   └── toast.dart        # Toast utilities (Now uses native SnackBar)
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

### **5. Updated Toast Implementation**

**Native SnackBar Integration:**
- Replaced fluttertoast with Flutter's built-in SnackBar
- Better performance and no external dependencies
- Consistent with Material Design guidelines

```dart
void showToast({
  required String msg,
  Color? backgroundColor,
  Color? textColor,
  BuildContext? context,
}) {
  if (context == null) {
    print('Toast: $msg');
    return;
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: TextStyle(color: textColor ?? Colors.white)),
      duration: const Duration(seconds: 2),
      backgroundColor: backgroundColor ?? ColorLight.primary,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
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

### **Prerequisites**
- **Flutter SDK**: `>=3.4.0 <4.0.0`
- **Dart SDK**: Compatible with Flutter version
- **Android Studio**: Latest version with SDK tools
- **Java**: OpenJDK 21 (for Android development)

### **Setup Steps**

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
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

### **Android Setup**
The project uses the latest Android build tools:
- **Android Gradle Plugin**: 8.6.0
- **Kotlin**: 2.1.0
- **Gradle**: 8.7
- **Target SDK**: 36

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
- ✅ **Native Toast Notifications**
- ✅ **Latest Android Build Tools**

## 🧪 Testing

The project includes testing setup with:
- `bloc_test` for BLoC testing
- `mocktail` for mocking
- `flutter_test` for widget testing

## 📚 Dependencies

### **Core Dependencies**
- `flutter_bloc` ^8.1.6 - State management
- `get_it` ^7.7.0 - Dependency injection
- `freezed_annotation` ^2.4.4 - Code generation
- `dio` ^5.9.0 - HTTP client
- `go_router` ^13.2.5 - Navigation
- `dartz` ^0.10.1 - Functional programming
- `shared_preferences` ^2.5.3 - Local storage

### **UI Dependencies**
- `google_fonts` ^6.3.0 - Typography
- `flutter_spinkit` ^5.2.2 - Loading indicators
- `font_awesome_flutter` ^10.9.0 - Icons
- **Removed**: `fluttertoast` (replaced with native SnackBar)

### **Development Dependencies**
- `very_good_analysis` ^3.1.0 - Linting
- `build_runner` ^2.7.0 - Code generation
- `bloc_test` ^9.1.7 - BLoC testing
- `mocktail` ^0.3.0 - Mocking

## 🔧 Configuration

### **Environment Setup**
- **Flutter SDK**: `>=3.4.0 <4.0.0`
- **Dart SDK**: Compatible with Flutter version
- **Android SDK**: Version 36.0.0
- **Java**: OpenJDK 21

### **Android Build Configuration**
```gradle
// android/build.gradle
buildscript {
    ext.kotlin_version = '2.1.0'
    dependencies {
        classpath 'com.android.tools.build:gradle:8.6.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

// android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-all.zip
```

### **Code Generation**
Run this command whenever you modify Freezed classes:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 🔄 Recent Changes

### **Build System Improvements**
- ✅ **Android Gradle Plugin**: 8.6.0
- ✅ **Kotlin**: 2.1.0
- ✅ **Gradle**: 8.7
- ✅ **Dart SDK**: >=3.4.0

### **Dependency Improvements**
- ✅ **79 dependencies upgraded** to latest compatible versions
- ✅ **Removed fluttertoast** dependency (replaced with native SnackBar)
- ✅ **All core packages** upgraded to latest stable versions

### **Bug Fixes**
- ✅ **Fixed MainActivity namespace issue** in AndroidManifest.xml
- ✅ **Resolved fluttertoast compatibility** with newer AGP versions
- ✅ **Toast implementation** now uses native Flutter SnackBar

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
