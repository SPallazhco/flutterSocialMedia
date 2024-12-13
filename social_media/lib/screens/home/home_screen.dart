import 'package:flutter/material.dart';
import 'package:social_media/screens/feed/feed_screen.dart';
import 'package:social_media/screens/profile/profile_screen.dart';
import 'package:social_media/screens/search/search_screen.dart';
import 'package:social_media/screens/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Índice de la pestaña seleccionada
  int _selectedIndex = 0;

  // Lista de pantallas que se mostrarán dependiendo de la pestaña seleccionada
  static const List<Widget> _widgetOptions = <Widget>[
    FeedScreen(), // Pantalla principal de publicaciones
    SearchScreen(), // Pantalla de búsqueda
    ProfileScreen(), // Pantalla del perfil
    SettingsScreen(), // Pantalla de configuraciones
  ];

  // Cuando se selecciona una pestaña, se actualiza el estado con el índice
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('YourSelf'),
          backgroundColor: Colors.blue, // Mantén el diseño coherente
        ),
        body: _widgetOptions[
            _selectedIndex], // Mostrar la pantalla basada en el índice
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade600
              ], // Degradado similar al del login
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Sombra suave
                spreadRadius: 5,
                blurRadius: 10,
                offset: const Offset(0, -3), // Sombra hacia arriba
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor:
                Colors.transparent, // Fondo transparente para aplicar el estilo
            selectedItemColor:
                Colors.white, // Color de los íconos seleccionados
            unselectedItemColor: Colors.white
                .withOpacity(0.6), // Color de los íconos no seleccionados
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            showUnselectedLabels:
                true, // Mostrar texto incluso si no está seleccionado
            type: BottomNavigationBarType.fixed, // Barra fija
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Feed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Buscar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: 'Perfil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Configuración',
              ),
            ],
          ),
        ));
  }
}
