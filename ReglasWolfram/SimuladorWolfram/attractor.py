import os
import networkx as nx
import matplotlib.pyplot as plt

def create_graph_from_file(file_path):
    G = nx.DiGraph()

    with open(file_path, 'r') as file:
        for line in file:
            source, target = map(int, line.strip().split())
            G.add_edge(source, target)
            
            # Add self-loop for recursive transitions (if source and target are the same)
            if source == target:
                G.add_edge(source, source)

    return G

def draw_graph(G, save_path):
    pos = nx.spring_layout(G)
    
    # Determine which nodes have self-loops
    self_loop_nodes = [node for node in G.nodes() if G.has_edge(node, node)]
    
    # Adjust node_size for self-loop nodes to make the circles smaller
    node_size = 10  # Default node size
    nx.draw(G, pos, with_labels=False, node_size=node_size, node_color="black", arrows=False)
    
    # Redraw self-loop nodes with a smaller node_size
    nx.draw_networkx_nodes(G, pos, nodelist=self_loop_nodes, node_size=node_size / 2, node_color="black")
    
    plt.savefig(save_path)
    plt.clf()  # Clear the current figure
    print(f"Image saved to {save_path}")

if __name__ == "__main__":
    folder_path = "C:/Users/Gael Hernández Solís/Desktop/JV"  # Replace with the path to your folder
    output_folder = "C:/Users/Gael Hernández Solís/Desktop/JV"  # Replace with the path to the folder where you want to save images

    # Create the output folder if it doesn't exist
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    # Iterate through all text files in the folder
    for filename in os.listdir(folder_path):
        if filename.endswith(".txt"):
            file_path = os.path.join(folder_path, filename)
            save_path = os.path.join(output_folder, f"{os.path.splitext(filename)[0]}.png")
            
            graph = create_graph_from_file(file_path)
            draw_graph(graph, save_path)
