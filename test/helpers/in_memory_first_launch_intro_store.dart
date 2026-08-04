import 'package:context_forge/services/first_launch_intro_store.dart';

/// In-memory [FirstLaunchIntroStore] for widget tests.
class InMemoryFirstLaunchIntroStore extends FirstLaunchIntroStore {
  InMemoryFirstLaunchIntroStore({this.introCompleted = true});

  bool introCompleted;

  @override
  Future<bool> shouldShowIntro() async => !introCompleted;

  @override
  Future<void> markIntroCompleted() async {
    introCompleted = true;
  }

  @override
  Future<void> reset() async {
    introCompleted = false;
  }
}