from pathlib import Path
import matplotlib.pyplot as plt
import sys

def draw_graph_summary(input_dir, outfile):
    """
    Merge all visualization of assembly graph into one.
    """
    assembly_graphs = Path(input_dir)
    title_dict = {0 : "A_flye",
                  1: "B_minipolish",
                  2: "C_raven",
                  3: "D_flye",
                  4: "E_minipolish",
                  5: "F_raven",
                  6: "G_flye",
                  7: "H_minipolish",
                  8: "I_raven",
                  9: "J_flye",
                  10: "K_minipolish",
                  11: "L_raven",
                 }
    images = [plt.imread(s) for s in assembly_graphs.glob("*.png")]
    plt.figure(figsize=(18,24))
    columns = 3
    for i, image in enumerate(images):
        plt.subplot(int(len(images) / columns + 1), columns, i + 1)
        plt.title(title_dict[i], fontsize=10)
        plt.axis('off')
        plt.imshow(image)
    plt.savefig(outfile)
    return None

if __name__ == "__main__":
    draw_graph_summary(sys.argv[1], sys.argv[2])