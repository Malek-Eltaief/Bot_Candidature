import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/job_details_screen.dart';
import '../theme/theme.dart';
import '../widgets/custom_scaffold.dart';
import '../services/database_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _removeFavorite(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _databaseService.removeFavorite(user.uid, jobId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job removed from favorites')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during removal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return CustomScaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 1,
        selectedItemColor: lightColorScheme.primary,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context, '/home');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              'My Favorite Jobs',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: user == null
                  ? const Center(child: Text('Please log in'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _databaseService.getFavorites(user.uid),
                      builder: (context, favoriteSnapshot) {
                        if (favoriteSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (favoriteSnapshot.hasError) {
                          return const Center(child: Text('An error has occurred'));
                        }
                        if (!favoriteSnapshot.hasData || favoriteSnapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No favorite jobs'));
                        }

                        final favoriteDocs = favoriteSnapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.all(20.0),
                          itemCount: favoriteDocs.length,
                          itemBuilder: (context, index) {
                            final favorite = favoriteDocs[index];
                            final jobId = favorite['jobId'];

                            return FutureBuilder<DocumentSnapshot>(
                              future: _databaseService.getJobById(jobId),
                              builder: (context, jobSnapshot) {
                                if (jobSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Card(
                                    margin: EdgeInsets.symmetric(vertical: 8.0),
                                    child: ListTile(title: Text('Loading...')),
                                  );
                                }
                                if (!jobSnapshot.hasData || !jobSnapshot.data!.exists) {
                                  return const SizedBox.shrink();
                                }

                                final jobData = jobSnapshot.data!.data() as Map<String, dynamic>;

                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(15.0),
                                    title: Text(
                                      jobData['title'] ?? 'No title',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(jobData['company'] ?? 'Unknown company'),
                                        Text(jobData['location'] ?? 'Unknown location'),
                                        Text(jobData['contractType'] ?? 'Unknown type'),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.favorite, color: Colors.red),
                                      onPressed: () => _removeFavorite(jobId),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => JobDetailsScreen(jobId: jobId),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
