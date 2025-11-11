import 'package:equatable/equatable.dart';

class DarkModeState extends Equatable {
  final bool isDarkMode;

  const DarkModeState({required this.isDarkMode});

  @override
  List<Object?> get props => [isDarkMode];
}
