import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Obtener datos del usuario
        final userDoc =
            await _firestore.collection('Users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data();
          });
        }
        // Inicializar lista vacía de publicaciones
        setState(() {
          userPosts = []; // Aquí llenaremos datos reales en el futuro.
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener datos del usuario: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Stack(
                children: [
                  // Contenido principal
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      // Información del usuario
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Imagen de perfil
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: userData?['profileImage'] != null
                                  ? NetworkImage(userData!['profileImage'])
                                  : null,
                              child: userData?['profileImage'] == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            // Nombre y apellido
                            Text(
                              "${userData?['username'] ?? 'Nombre'} ${userData?['lastname'] ?? 'Apellido'}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Correo electrónico
                            Text(
                              userData?['email'] ?? 'Correo no disponible',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const Divider(height: 32),
                          ],
                        ),
                      ),
                      // Sección de publicaciones
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Publicaciones",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            userPosts.isEmpty
                                ? const Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Aún no hay publicaciones",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 4.0,
                                      mainAxisSpacing: 4.0,
                                    ),
                                    itemCount: userPosts.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Image.network(
                                          userPosts[index]['imageUrl'],
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Botón de configuración flotante en la parte superior derecha
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.black),
                      onPressed: () {
                        Navigator.pushNamed(context, 'settings');
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
