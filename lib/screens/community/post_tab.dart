import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart' as app_provider;

class PostTab extends StatefulWidget {
  const PostTab({super.key});

  @override
  _PostTabState createState() => _PostTabState();
}

class _PostTabState extends State<PostTab> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_provider.AuthProvider>(context);
    final user = authProvider.currentUser;

    return Column(
      children: [
        ListTile(
          leading: const CircleAvatar(
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          title: Text(user?.displayName ?? "User"),
          subtitle: const Text("What's on your mind?"),
          trailing: const Icon(Icons.public),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostPage()),
            );
          },
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community_posts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading posts"));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final posts = snapshot.data!.docs;
              if (posts.isEmpty) {
                return const Center(child: Text("No posts available"));
              }
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  var post = posts[index].data() as Map<String, dynamic>;
                  String postId = posts[index].id;
                  bool isLiked = false; // Local state; enhance later

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                      ),
                      title: Text(post['userName'] ?? "Unknown User"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['description'] ?? ""),
                          if (post['media'] != null && post['media'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Image.network(
                                post['media'][0],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text("Failed to load image");
                                },
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: isLiked ? Colors.red : null,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      if (user == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please sign in to like")),
                                        );
                                        return;
                                      }
                                      await FirebaseFirestore.instance
                                          .collection('community_posts')
                                          .doc(postId)
                                          .update({
                                        'likes': FieldValue.increment(isLiked ? -1 : 1),
                                      });
                                      setState(() {
                                        isLiked = !isLiked;
                                      });
                                    },
                                  ),
                                  Text('${post['likes'] ?? 0}'),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.comment, size: 20),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PostDetailPage(postId: postId),
                                        ),
                                      );
                                    },
                                  ),
                                  Text('${post['comments']?.length ?? 0}'),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                onPressed: () async {
                                  await Share.share(
                                    '${post['title'] ?? ''}\n${post['description'] ?? ''}',
                                  );
                                  await FirebaseFirestore.instance
                                      .collection('community_posts')
                                      .doc(postId)
                                      .update({
                                    'shares': FieldValue.increment(1),
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailPage(postId: postId),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_provider.AuthProvider>(context);
    final user = authProvider.currentUser;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C34),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User not authenticated")),
                  );
                  return;
                }
                await FirebaseFirestore.instance.collection('community_posts').add({
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'userId': user.uid,
                  'userName': user.displayName ?? "Anonymous",
                  'userRole': 'Responder',
                  'timestamp': FieldValue.serverTimestamp(),
                  'type': 'Medical',
                  'urgency': 'High',
                  'location': {
                    'lat': -1.9441,
                    'lng': 30.0619,
                    'name': 'Kigali, Sector 5',
                  },
                  'media': ['https://via.placeholder.com/150'],
                  'likes': 0,
                  'shares': 0,
                  'status': 'Open',
                  'comments': [],
                });
                Navigator.pop(context);
              },
              child: const Text("Submit Post"),
            ),
          ],
        ),
      ),
    );
  }
}

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_provider.AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Detail"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading post"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var post = snapshot.data!.data() as Map<String, dynamic>;
          bool isLiked = false; // Local state; enhance later

          return SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                  ),
                  title: Text(post['userName'] ?? "Unknown User"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['description'] ?? ""),
                      if (post['media'] != null && post['media'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(
                            post['media'][0],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text("Failed to load image");
                            },
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : null,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please sign in to like")),
                                    );
                                    return;
                                  }
                                  await FirebaseFirestore.instance
                                      .collection('community_posts')
                                      .doc(widget.postId)
                                      .update({
                                    'likes': FieldValue.increment(isLiked ? -1 : 1),
                                  });
                                  setState(() {
                                    isLiked = !isLiked;
                                  });
                                },
                              ),
                              Text('${post['likes'] ?? 0}'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.comment, size: 20),
                              const SizedBox(width: 4),
                              Text('${post['comments']?.length ?? 0}'),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, size: 20),
                            onPressed: () async {
                              await Share.share(
                                '${post['title'] ?? ''}\n${post['description'] ?? ''}',
                              );
                              await FirebaseFirestore.instance
                                  .collection('community_posts')
                                  .doc(widget.postId)
                                  .update({
                                'shares': FieldValue.increment(1),
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (post['comments'] != null && post['comments'].isNotEmpty)
                  ...post['comments'].map<Widget>((comment) => ListTile(
                        leading: const CircleAvatar(
                          backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                        ),
                        title: Text(comment['userName'] ?? "Unknown User"),
                        subtitle: Text(comment['text'] ?? ""),
                        trailing: TextButton(
                          onPressed: () {}, // Add reply functionality if needed
                          child: const Text("Reply"),
                        ),
                      ))
                else
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No comments yet"),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: const Color(0xFF1A3C34)),
                        onPressed: () async {
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("User not authenticated")),
                            );
                            return;
                          }
                          if (_commentController.text.trim().isEmpty) return;
                          await FirebaseFirestore.instance
                              .collection('community_posts')
                              .doc(widget.postId)
                              .update({
                            'comments': FieldValue.arrayUnion([
                              {
                                'userId': user.uid,
                                'userName': user.displayName ?? "Anonymous",
                                'text': _commentController.text.trim(),
                                'timestamp': FieldValue.serverTimestamp(),
                              }
                            ]),
                          });
                          _commentController.clear();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}