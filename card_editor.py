import tkinter as tk
from tkinter import ttk
import json

class JSONCustomizerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("JSON Customizer")

        # Load JSON template
        with open("template.json", "r") as template_file:
            self.template_data = json.load(template_file)

        # Create UI elements
        self.create_widgets()

    def create_widgets(self):
        # Create a treeview to display and edit JSON elements
        self.tree = ttk.Treeview(self.root, columns=("Value",), selectmode="browse")
        self.tree.heading("#0", text="JSON Customizer")
        self.tree.heading("Value", text="Value")
        self.tree.column("Value", stretch=tk.YES)
        self.tree.pack(expand=True, fill="both")

        # Populate treeview with JSON elements
        self.populate_tree(self.template_data, "")

        # Create a button to save the customized JSON
        save_button = ttk.Button(self.root, text="Save Customization", command=self.save_customization)
        save_button.pack()

    def populate_tree(self, data, parent):
        if isinstance(data, dict):
            for key, value in data.items():
                item = self.tree.insert(parent, "end", text=key)
                self.populate_tree(value, item)
        elif isinstance(data, list):
            for i, item in enumerate(data):
                item_text = f"[{i}]"
                sub_item = self.tree.insert(parent, "end", text=item_text)
                self.populate_tree(item, sub_item)
        else:
            # For leaf nodes, add an Entry widget for editing
            value = str(data)
            item = self.tree.insert(parent, "end", text=value)
            entry = ttk.Entry(self.tree, show='', justify='left')
            entry.insert(0, value)
            self.tree.set(item, "Value", entry)

    def save_customization(self):
        # Create a dictionary to store customized data
        customized_data = {}

        # Traverse the treeview to get customized values
        for child in self.tree.get_children():
            self.traverse_tree(child, customized_data)

        # Save customized data to a new JSON file
        with open("customized.json", "w") as customized_file:
            json.dump(customized_data, customized_file, indent=2)

        print("Customization saved to 'customized.json'")

    def traverse_tree(self, item, customized_data):
        item_text = self.tree.item(item, "text")

        if self.tree.get_children(item):
            # Item has children, so it's a dictionary or list
            if item_text.startswith("["):
                # It's a list
                index = int(item_text[1:-1])
                customized_data[index] = []
                for child in self.tree.get_children(item):
                    sub_data = {}
                    self.traverse_tree(child, sub_data)
                    customized_data[index].append(sub_data)
            else:
                # It's a dictionary
                customized_data[item_text] = {}
                for child in self.tree.get_children(item):
                    sub_data = {}
                    self.traverse_tree(child, sub_data)
                    customized_data[item_text].update(sub_data)
        else:
            # Item is a leaf node, so it's a value
            entry_text = self.tree.set(item, "Value")
            if item_text.startswith("["):
                # Convert index to integer for list
                index = int(item_text[1:-1])
                customized_data[index] = entry_text
            else:
                customized_data[item_text] = entry_text

if __name__ == "__main__":
    root = tk.Tk()
    app = JSONCustomizerApp(root)
    root.mainloop()
