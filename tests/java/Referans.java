// tests/java/Referans.java
// Hocanın Atlas sınıflarını HİÇ DEĞİŞTİRMEDEN çağırır ve karşılaştırma için
// üç satır yazar: Main çıktısı, printPath çıktısı, getTestSuite çıktısı.
// Kullanım: tests/java_karsilastir.sh
import java.util.LinkedList;

public class Referans {
    public static void main(String[] args) throws Exception {
        Graph graph = new Util().toGraph(args[0]);
        Atlas atlas = new Atlas();
        System.out.println("atlas: " + atlas.run(graph).length());
        LinkedList<Integer> path = atlas.longestPath(graph, graph.getStarts().iterator().next());
        atlas.printPath(graph, path);
        System.out.println(atlas.getTestSuite(graph, path));
    }
}
