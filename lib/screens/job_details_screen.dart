import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme.dart';
import '../widgets/custom_scaffold.dart';
import '../screens/edit_job_screen.dart';
import '../services/database_service.dart';
import '../models/job_model.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isFavorite = false;
  bool _isLoading = false;
  String? _userRole;
  JobModel? _job;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jobDoc = await _databaseService.getJobById(widget.jobId);
      if (!jobDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job not found')),
        );
        Navigator.pop(context);
        return;
      }

      final job = JobModel.fromFirestore(jobDoc);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
        }
        return;
      }

      final isFav = await _databaseService.isFavoriteJob(widget.jobId);
      final role = await _databaseService.getUserRole();

      if (mounted) {
        setState(() {
          _job = job;
          _isFavorite = isFav;
          _userRole = role;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job data: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      await _databaseService.toggleFavorite(widget.jobId);
      final newStatus = await _databaseService.isFavoriteJob(widget.jobId);
      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling favorite: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteJob() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      await _databaseService.deleteJob(widget.jobId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting job: $e')),
        );
      }
    }
  }

  Widget _buildJobInfo() {
    if (_job == null) return const Center(child: CircularProgressIndicator());
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'Job Details',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _job!.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_userRole == 'recruiter' && _job!.createdBy == user?.uid) ...[
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditJobScreen(
                                  jobId: widget.jobId,
                                  job: _job!,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _deleteJob,
                        ),
                      ],
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: _isLoading ? null : _toggleFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_job!.company, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  Text(_job!.location),
                  Text(_job!.contractType),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_job!.description),
                  const SizedBox(height: 20),
                  if (_userRole != 'recruiter')
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'id': widget.jobId,
                              'title': _job!.title,
                              'description': _job!.description,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightColorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: const Text('Apply', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: lightColorScheme.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 1) Navigator.pushReplacementNamed(context, '/favorites');
          if (index == 2) Navigator.pushReplacementNamed(context, '/profile');
        },
      ),
      child: _buildJobInfo(),
    );
  }
}