import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme.dart';
import '../widgets/custom_scaffold.dart';
import 'signin_screen.dart';
import 'recruiter_offers_screen.dart';
import 'edit_profile_screen.dart';
import '../services/database_service.dart';  // Import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();

  String _fullName = '';
  String _email = '';
  String _jobTitle = '';
  String _location = '';
  bool _isRecruiter = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await _databaseService.getUserData(user.uid);
      if (mounted && data != null) {
        setState(() {
          _fullName = data['fullName'] ?? user.displayName ?? '';
          _email = data['email'] ?? user.email ?? '';
          _jobTitle = data['jobPosition'] ?? '';
          _location = data['location'] ?? '';
          _isRecruiter = (data['role'] == 'recruiter'); // Suppose que tu as un champ 'role'
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => EditProfileScreen(
        onSave: (String fullName, String email, String job, String location) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return 'User not authenticated';

          try {
            await _databaseService.getUserProfile(
              uid: user.uid,
              fullName: fullName,
              email: email,
              jobPosition: job,
              location: location,
            );
            if (mounted) {
              setState(() {
                _fullName = fullName;
                _email = email;
                _jobTitle = job;
                _location = location;
              });
            }
            return null; // Succès
          } catch (e) {
            return 'Error saving data: $e';
          }
        },
        initialName: _fullName,
        initialEmail: _email,
      ),
    );
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
        currentIndex: 2,
        selectedItemColor: lightColorScheme.primary,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/favorites');
          }
        },
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40.0),
                      topRight: Radius.circular(40.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withAlpha((0.3 * 255).toInt()),
                        blurRadius: 12.0,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                             backgroundImage: user?.photoURL != null
    ? NetworkImage(user!.photoURL!)
    : null,
                              child: user?.photoURL == null
                                  ? const Icon(Icons.person, size: 55, color: Colors.white)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 30, color: Colors.blue),
                              onPressed: _showEditProfileModal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          _fullName,
                          style: const TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          'Email: $_email',
                          style: const TextStyle(fontSize: 18.0, color: Colors.grey),
                        ),
                        if (_jobTitle.isNotEmpty) ...[
                          const SizedBox(height: 10.0),
                          Text(
                            'Job Position: $_jobTitle',
                            style: const TextStyle(fontSize: 18.0, color: Colors.grey),
                          ),
                        ],
                        if (_location.isNotEmpty) ...[
                          const SizedBox(height: 10.0),
                          Text(
                            'Location: $_location',
                            style: const TextStyle(fontSize: 18.0, color: Colors.grey),
                          ),
                        ],
                        const Spacer(),
                        if (_isRecruiter) ...[
                          const SizedBox(height: 20.0),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RecruiterOffersScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lightColorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              elevation: 6.0,
                            ),
                            child: const Text(
                              'View Associated Offers',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 15.0,
            right: 20.0,
            child: IconButton(
              icon: const Icon(Icons.logout, size: 30, color: Colors.white),
              onPressed: _signOut,
            ),
          ),
        ],
      ),
    );
  }
}
