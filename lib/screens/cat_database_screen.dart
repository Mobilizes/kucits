import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';
import '../services/user_service.dart';
import '../widgets/map_view_overlay.dart';

class CatDatabaseScreen extends StatefulWidget {
  const CatDatabaseScreen({super.key});

  @override
  State<CatDatabaseScreen> createState() => _CatDatabaseScreenState();
}

class _CatDatabaseScreenState extends State<CatDatabaseScreen> {
  String? _selectedFaculty;
  String? _selectedDepartment;
  bool? _neuteredFilter; // null = all, true = neutered, false = intact

  bool _isAdmin = false;
  bool _loadingAdminCheck = true;

  final Map<String, List<String>> _faculties = {
    'FSAD (Sains & Analitika Data)': ['Fisika', 'Kimia', 'Matematika', 'Biologi', 'Statistika', 'Aktuaria'],
    'FTIRS (Teknologi Industri)': ['Teknik Mesin', 'Teknik Kimia', 'Teknik Fisika', 'Rekayasa Keselamatan Proses', 'Teknik Industri', 'Teknik Material dan Metalurgi', 'Teknik Pangan'],
    'FTK (Teknologi Kelautan)': ['Teknik Perkapalan', 'Teknik Sistem Perkapalan', 'Teknik Kelautan', 'Teknik Transportasi Laut', 'Teknik Lepas Pantai'],
    'FTSPK (Sipil, Perencanaan & Kebumian)': ['Teknik Sipil', 'Arsitektur', 'Teknik Lingkungan', 'Teknik Geomatika', 'Perencanaan Wilayah Kota', 'Teknik Geofisika', 'Teknik Pertambangan'],
    'FTEIC (Elektro & Informatika)': ['Teknik Elektro', 'Teknik Informatika', 'Sistem Informasi', 'Teknik Komputer', 'Teknik Biomedik', 'Teknologi Informasi', 'Teknik Telekomunikasi'],
    'FDKBD (Desain Kreatif & Bisnis)': ['Desain Produk', 'Desain Interior', 'Desain Komunikasi Visual', 'Manajemen Bisnis', 'Studi Pembangunan'],
    'FV (Vokasi)': ['Teknik Infrastruktur Sipil', 'Teknik Mesin Industri', 'Teknik Elektro Otomasi', 'Teknik Kimia Industri', 'Teknik Instrumentasi', 'Statistika Bisnis'],
    'FKK (Kedokteran & Kesehatan)': ['Teknologi Kedokteran', 'Kedokteran'],
  };

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        final userService = Provider.of<UserService>(context, listen: false);
        final profile = await userService.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _isAdmin = profile?.isAdmin ?? false;
            _loadingAdminCheck = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _loadingAdminCheck = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingAdminCheck = false;
        });
      }
    }
  }

  List<String> get _departments {
    if (_selectedFaculty == null) return [];
    return _faculties[_selectedFaculty] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final catService = Provider.of<CatService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Cats',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Collapsible Map View Overlay
          const MapViewOverlay(),
          
          // Filters UI
          _buildFilterPanel(colorScheme),
          
          // Grid List of Cats
          Expanded(
            child: StreamBuilder<List<Cat>>(
              stream: catService.streamCats(department: _selectedDepartment),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading cats: ${snapshot.error}',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  );
                }

                var cats = snapshot.data ?? [];

                // Perform client-side Faculty filtering if Faculty is selected but Department is not
                if (_selectedFaculty != null && _selectedDepartment == null) {
                  final facultyDeps = _faculties[_selectedFaculty] ?? [];
                  cats = cats.where((cat) => facultyDeps.contains(cat.department)).toList();
                }

                // Perform client-side Neutered status filtering
                if (_neuteredFilter != null) {
                  cats = cats.where((cat) => cat.isNeutered == _neuteredFilter).toList();
                }

                if (cats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No cats matching filters found.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: cats.length,
                  itemBuilder: (context, index) {
                    final cat = cats[index];
                    return _buildCatCard(context, cat, colorScheme);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !_loadingAdminCheck && _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cats/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Cat'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildFilterPanel(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: cs.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            children: [
              // Faculty Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedFaculty,
                      hint: const Text('All Faculties', style: TextStyle(fontSize: 12)),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Faculties', style: TextStyle(fontSize: 12)),
                        ),
                        ..._faculties.keys.map((faculty) {
                          return DropdownMenuItem<String>(
                            value: faculty,
                            child: Text(
                              faculty,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedFaculty = val;
                          _selectedDepartment = null; // Reset department
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Department Filter (dependent on selected Faculty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedDepartment,
                      hint: const Text('All Depts', style: TextStyle(fontSize: 12)),
                      disabledHint: const Text('Select Faculty first', style: TextStyle(fontSize: 11)),
                      items: _selectedFaculty == null
                          ? null
                          : [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Depts', style: TextStyle(fontSize: 12)),
                              ),
                              ..._departments.map((dept) {
                                return DropdownMenuItem<String>(
                                  value: dept,
                                  child: Text(
                                    dept,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                      onChanged: _selectedFaculty == null
                          ? null
                          : (val) {
                              setState(() {
                                _selectedDepartment = val;
                              });
                            },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Neutered Filter chips
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Neutered Status: ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All', style: TextStyle(fontSize: 11)),
                selected: _neuteredFilter == null,
                onSelected: (_) => setState(() => _neuteredFilter = null),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Neutered', style: TextStyle(fontSize: 11)),
                selected: _neuteredFilter == true,
                onSelected: (_) => setState(() => _neuteredFilter = true),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Intact', style: TextStyle(fontSize: 11)),
                selected: _neuteredFilter == false,
                onSelected: (_) => setState(() => _neuteredFilter = false),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatCard(BuildContext context, Cat cat, ColorScheme cs) {
    final hasImage = cat.iconUrl.isNotEmpty;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => context.push('/cats/${cat.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cat Photo / Initials Placeholder
            Expanded(
              child: Container(
                color: cs.surfaceContainerHighest,
                child: hasImage
                    ? Image.network(
                        cat.iconUrl,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          cat.name.isNotEmpty ? cat.name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
              ),
            ),
            
            // Cat Info Info Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cat.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (cat.isNeutered) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Neutered',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cat.department,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
