// lib/widgets/custom_scaffold.dart
import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({
    super.key,
    this.child,
    this.floatingActionButton, // Ajout pour compatibilité
    this.bottomNavigationBar, // Ajout pour compatibilité
  });

  final Widget? child;
  final Widget? floatingActionButton; // Paramètre ajouté
  final Widget? bottomNavigationBar; // Paramètre ajouté

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: floatingActionButton, // Utilisation du paramètre
      bottomNavigationBar: bottomNavigationBar, // Utilisation du paramètre
      body: Stack(
        children: [
          Image.asset(
            'assets/images/background1.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: child!,
          ),
        ],
      ),
    );
  }
}