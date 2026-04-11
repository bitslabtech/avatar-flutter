// Add this method before the closing brace of _AdminOrderDetailScreenState class
// Around line 679, before _formatAddress method

Widget _buildOrderItemRow(dynamic item, bool isDark) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            image: item.imageUrl != null ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover) : null,
          ),
          child: item.imageUrl == null ? const Icon(Icons.image_not_supported, size: 20, color: Colors.grey) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark?Colors.white:Colors.black87)),
              const SizedBox(height: 4),
              Text('SKU: ${item.sku ?? "N/A"}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              const SizedBox(height: 4),
              if (_isEditingItems)
                Row(
                  children: [
                    Text(
                      CurrencyUtils.formatPaise(item.dpPricePaise),
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    const Text('Qty:', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Container(
                      width: 60,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: item.qty.toString()),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() => _isDirty = true),
                      ),
                    ),
                  ],
                )
              else
                Text.rich(TextSpan(
                  text: CurrencyUtils.formatPaise(item.dpPricePaise),
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 12),
                  children: [ TextSpan(text: ' x ${item.qty}', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.normal)) ]
                )),
            ],
          ),
        ),
        if (_isEditingItems)
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            onPressed: () => setState(() => _isDirty = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    ),
  );
}

// THEN REPLACE in _buildItemsSection (around line 412-445):
// Change from:
//   children: order.items.map((item) => Padding(...)).toList(),
// To:
//   children: order.items.map((item) => _buildOrderItemRow(item, isDark)).toList(),

// THEN ADD after line 447 (after the closing of items container, before the SizedBox):
          if (_isEditingItems) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Show product picker dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product picker coming soon')),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditingItems = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Save item changes
                      setState(() {
                        _isEditingItems = false;
                        _isDirty = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Items updated (API integration needed)'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
