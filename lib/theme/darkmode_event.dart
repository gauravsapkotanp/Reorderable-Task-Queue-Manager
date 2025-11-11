import 'package:equatable/equatable.dart';

abstract class DarkModeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ToggleDarkMode extends DarkModeEvent {}

class LoadDarkMode extends DarkModeEvent {
  final bool darkMode;

  LoadDarkMode(this.darkMode);

  @override
  List<Object?> get props => [darkMode];
}
