import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _activeTab = "METRICS"; // METRICS or PIPELINE

  final List<WorkflowNode> _nodes = [
    const WorkflowNode(
      title: "User Input Trigger",
      desc: "Client payload captured & parsed",
      status: NodeStatus.completed,
      step: 1,
    ),
    const WorkflowNode(
      title: "Webhook Activated",
      desc: "POST https://your-n8n-domain.com/webhook/...",
      status: NodeStatus.completed,
      step: 2,
    ),
    const WorkflowNode(
      title: "n8n Router Engine",
      desc: "Executing n8n workflows orchestrations",
      status: NodeStatus.active,
      step: 3,
    ),
    const WorkflowNode(
      title: "Extract Keywords NLP",
      desc: "Scanning terms: 'conspiracy, leak, government'",
      status: NodeStatus.active,
      step: 4,
    ),
    const WorkflowNode(
      title: "AI Verification Scoring",
      desc: "Running StyleGAN/DeepFace & LLM weights",
      status: NodeStatus.active,
      step: 5,
    ),
    const WorkflowNode(
      title: "Fact Check API Queries",
      desc: "Invoking Reuters, AltNews, PIB databases",
      status: NodeStatus.idle,
      step: 6,
    ),
    const WorkflowNode(
      title: "Reverse Image Search",
      desc: "Matching TinEye & Google Lens signatures",
      status: NodeStatus.idle,
      step: 7,
    ),
    const WorkflowNode(
      title: "Source Backtracking",
      desc: "Compiling telegram/twitter timeline nodes",
      status: NodeStatus.idle,
      step: 8,
    ),
    const WorkflowNode(
      title: "Generate Evidence Dossier",
      desc: "Wrapping trust reports into standard JSON",
      status: NodeStatus.pending,
      step: 9,
    ),
    const WorkflowNode(
      title: "Transmit Flutter Response",
      desc: "Returning encrypted result payload to UI",
      status: NodeStatus.pending,
      step: 10,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Admin & Diagnostics Portal",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      body: Column(
        children: [
          // Sub tabs selector
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton("SYSTEM METRICS", _activeTab == "METRICS", () {
                    setState(() {
                      _activeTab = "METRICS";
                    });
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSubTabButton("n8n AI PIPELINE", _activeTab == "PIPELINE", () {
                    setState(() {
                      _activeTab = "PIPELINE";
                    });
                  }),
                ),
              ],
            ),
          ),

          // Main body panels
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _activeTab == "METRICS" 
                  ? _buildMetricsPanel(theme, isDark)
                  : _buildPipelinePanel(theme, isDark),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsPanel(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status row
        Row(
          children: [
            Expanded(
              child: _buildMetricTile("Scanned Files", "1,482", const Color(0xFF4338CA), "Total verified items"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile("Flagged Fake", "412", const Color(0xFFEF4444), "Conspiracies/Phishings"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile("Active Keys", "89", const Color(0xFF10B981), "Verified officer keys"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile("n8n Uptime", "99.98%", const Color(0xFFF59E0B), "Active webhooks"),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Reported list
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "RECENT SUSPECT LOGS",
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildRecentLogItem("URL Phishing link blocked", "TRUTH-URL-2026-0043", "Dangerous", const Color(0xFFEF4444)),
              const Divider(),
              _buildRecentLogItem("StyleGAN3 Deepfake signature", "TRUTH-IMG-2026-1025", "Suspicious", const Color(0xFFF59E0B)),
              const Divider(),
              _buildRecentLogItem("NASA weather anomalies check", "TRUTH-NWS-2026-8092", "Real", const Color(0xFF10B981)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color accentColor, String desc) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 9, color: isDark ? Colors.grey[500] : Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildRecentLogItem(String title, String id, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Verification ID: $id",
                  style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor, fontFamily: 'monospace'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPipelinePanel(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top n8n banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4B00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF4B00).withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.hub_outlined, color: Color(0xFFFF4B00), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "n8n Workflow Execution Model active. All verification pipelines orchestrate triggers to live webhooks.",
                  style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Pipeline nodes vertical list
        const Text(
          "AI INVESTIGATION PIPELINE STATUS",
          style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _nodes.length,
          itemBuilder: (context, index) {
            final node = _nodes[index];
            final isLast = index == _nodes.length - 1;

            Color dotColor;
            Widget statusWidget;

            switch (node.status) {
              case NodeStatus.completed:
                dotColor = const Color(0xFF10B981);
                statusWidget = const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14);
                break;
              case NodeStatus.active:
                dotColor = const Color(0xFF4338CA);
                statusWidget = const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
                break;
              case NodeStatus.idle:
                dotColor = const Color(0xFFF59E0B);
                statusWidget = const Icon(Icons.pause_circle_outline, color: Color(0xFFF59E0B), size: 14);
                break;
              case NodeStatus.pending:
                dotColor = Colors.grey[700]!;
                statusWidget = const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 14);
                break;
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline line and dot representation
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor.withOpacity(0.2),
                          border: Border.all(color: dotColor, width: 2),
                        ),
                        child: node.status == NodeStatus.active 
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4338CA)),
                              ),
                            )
                          : null,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: theme.dividerColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Node content card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "[Step ${node.step}] ${node.title}",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    node.desc,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            statusWidget,
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        )
      ],
    );
  }
}

enum NodeStatus { completed, active, idle, pending }

class WorkflowNode {
  final String title;
  final String desc;
  final NodeStatus status;
  final int step;

  const WorkflowNode({
    required this.title,
    required this.desc,
    required this.status,
    required this.step,
  });
}
