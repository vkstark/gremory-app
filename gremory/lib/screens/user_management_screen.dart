import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../theme/fallback_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: FallbackTheme.backgroundLight,
        foregroundColor: FallbackTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: FallbackTheme.primaryPurple,
          unselectedLabelColor: FallbackTheme.textSecondary,
          indicatorColor: FallbackTheme.primaryPurple,
          tabs: const [
            Tab(text: 'Current User', icon: Icon(Icons.person)),
            Tab(text: 'All Users', icon: Icon(Icons.group)),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      authProvider.loadAvailableUsers();
                      break;
                    case 'seed':
                      _seedTestUsers(authProvider);
                      break;
                    case 'logout':
                      _showLogoutConfirmation(authProvider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 16),
                        SizedBox(width: 8),
                        Text('Refresh Users'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'seed',
                    child: Row(
                      children: [
                        Icon(Icons.group_add, size: 16),
                        SizedBox(width: 8),
                        Text('Seed Test Users'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentUserTab(),
          _buildAllUsersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserDialog(),
        backgroundColor: FallbackTheme.primaryPurple,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildCurrentUserTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: FallbackTheme.primaryPurple),
          );
        }

        final user = authProvider.currentUser;
        if (user == null) {
          return _buildNoUserState(authProvider);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 32),
              _buildUserInfo(user),
              if (authProvider.error != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(authProvider.error!),
              ],
              if (user.isGuest) ...[
                const SizedBox(height: 32),
                _buildGuestUpgradeSection(authProvider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllUsersTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: FallbackTheme.primaryPurple),
          );
        }

        if (authProvider.availableUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 64,
                  color: FallbackTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Users Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: FallbackTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create some users or seed test data',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FallbackTheme.textLight,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _seedTestUsers(authProvider),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Seed Test Users'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: FallbackTheme.primaryPurple,
          onRefresh: () => authProvider.loadAvailableUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: authProvider.availableUsers.length,
            itemBuilder: (context, index) {
              final user = authProvider.availableUsers[index];
              final isCurrentUser = authProvider.currentUser?.id == user.id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isCurrentUser ? 4 : 1,
                color: isCurrentUser ? FallbackTheme.palePurple : FallbackTheme.backgroundCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCurrentUser ? FallbackTheme.primaryPurple : FallbackTheme.borderLight,
                    width: isCurrentUser ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentUser ? FallbackTheme.primaryPurple : FallbackTheme.surfacePurple,
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : FallbackTheme.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                            color: isCurrentUser ? FallbackTheme.primaryPurple : FallbackTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FallbackTheme.primaryPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.username != null || user.email != null)
                        Text(
                          user.displayIdentifier,
                          style: const TextStyle(fontSize: 12),
                        ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getUserTypeColor(user.userType).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.userType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getUserTypeColor(user.userType),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ID: ${user.id}',
                            style: TextStyle(
                              fontSize: 10,
                              color: FallbackTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isCurrentUser) ...[
                        IconButton(
                          onPressed: () => _switchToUser(authProvider, user),
                          icon: const Icon(Icons.switch_account, size: 20),
                          tooltip: 'Switch to this user',
                          color: FallbackTheme.primaryPurple,
                        ),
                        IconButton(
                          onPressed: () => _showDeleteUserConfirmation(authProvider, user),
                          icon: const Icon(Icons.delete, size: 20),
                          tooltip: 'Delete user',
                          color: Colors.red,
                        ),
                      ] else ...[
                        IconButton(
                          onPressed: () => _showEditUserDialog(authProvider, user),
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Edit profile',
                          color: FallbackTheme.primaryPurple,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'registered':
        return Colors.green;
      case 'guest':
        return Colors.orange;
      case 'bot':
        return Colors.blue;
      default:
        return FallbackTheme.textSecondary;
    }
  }

  Widget _buildNoUserState(AuthProvider authProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: FallbackTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No User Logged In',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: FallbackTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we set up your profile',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FallbackTheme.textLight,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => authProvider.initialize(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FallbackTheme.primaryPurple, FallbackTheme.lightPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (user.username != null && user.username!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
                if (user.email != null && user.email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.userType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(User user) {
    return Card(
      elevation: 0,
      color: FallbackTheme.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FallbackTheme.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FallbackTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('User ID', user.id.toString()),
            _buildInfoRow('Username', user.username ?? 'Not set'),
            _buildInfoRow('Display Name', user.displayName),
            _buildInfoRow('Email', user.email ?? 'Not set'),
            _buildInfoRow('Phone', user.phoneNumber ?? 'Not set'),
            _buildInfoRow('Account Type', user.userType.toUpperCase()),
            _buildInfoRow('Status', user.status.toUpperCase()),
            _buildInfoRow('Language', user.languagePreference.toUpperCase()),
            _buildInfoRow('Timezone', user.timezone ?? 'Not set'),
            _buildInfoRow('Member Since', _formatDate(user.createdAt)),
            _buildInfoRow('Last Updated', _formatDate(user.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FallbackTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FallbackTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestUpgradeSection(AuthProvider authProvider) {
    return Card(
      elevation: 0,
      color: FallbackTheme.palePurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FallbackTheme.lightPurple),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.upgrade, color: FallbackTheme.primaryPurple),
                const SizedBox(width: 12),
                Text(
                  'Upgrade Your Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: FallbackTheme.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Create a registered account to save your conversations and access them from any device.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FallbackTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateUserDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Register Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FallbackTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter username (optional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && 
                        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name *',
                    hintText: 'Enter display name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Display name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter phone number (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
            child: const Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return ElevatedButton(
                onPressed: () => _handleCreateUser(authProvider),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create User'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(AuthProvider authProvider, User user) {
    _usernameController.text = user.username ?? '';
    _emailController.text = user.email ?? '';
    _displayNameController.text = user.displayName;
    _phoneController.text = user.phoneNumber ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User Profile'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Display name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _handleUpdateUser(authProvider),
            child: authProvider.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _handleCreateUser(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() == true) {
      await authProvider.createAndSwitchToNewUser(
        username: _usernameController.text.trim().isNotEmpty ? _usernameController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        displayName: _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      if (mounted && authProvider.error == null) {
        Navigator.of(context).pop();
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _handleUpdateUser(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() == true) {
      await authProvider.updateUserProfile(
        username: _usernameController.text.trim().isNotEmpty ? _usernameController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        displayName: _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      if (mounted && authProvider.error == null) {
        Navigator.of(context).pop();
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _switchToUser(AuthProvider authProvider, User user) async {
    await authProvider.switchToUser(user);
    
    if (mounted && authProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${user.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDeleteUserConfirmation(AuthProvider authProvider, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "${user.displayName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final userName = user.displayName;
              
              navigator.pop();
              await authProvider.deleteUser(user.id);
              
              if (mounted && authProvider.error == null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('$userName deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _seedTestUsers(AuthProvider authProvider) async {
    await authProvider.seedTestUsers();
    
    if (mounted && authProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test users created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showLogoutConfirmation(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? You will become a guest user.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _usernameController.clear();
    _emailController.clear();
    _displayNameController.clear();
    _phoneController.clear();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
