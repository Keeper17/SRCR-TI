import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

//classe usada para guardar as informações relativas às arestas
class Aresta{
    public int inicio;
    public int fim;
    public double distance;

    public Aresta(int inicio, int fim, double distance){
        this.inicio = inicio;
        this.fim = fim;
        this.distance = distance;
    }

    public boolean equals(Object o){
        if(o == null) return false;
        Aresta a = (Aresta)o;
        return this.inicio == a.inicio
                && this.fim == a.fim
                && this.distance == a.distance;
    }
}

public class readInfo {
    private static Map<String, List<Integer>> paragens = new HashMap<>();
    private static Map<String, Integer> linhas = new HashMap<>();
    private static Map<Integer, float[]> coords = new HashMap<>();
    private static List<Aresta> arestas = new ArrayList<>();


    //Método usado para calcular a distância entre as paragens usada nas arestas
    private static double distance(float x1, float y1, float x2, float y2){
        double R = 6371e3;
        double psi1 = x1 * Math.PI/180;
        double psi2 = x2 * Math.PI/180;
        double delta_psi = (x2 - x1) * Math.PI/180;
        double delta_lambda = (y2 - y1) * Math.PI/180;

        double a = Math.pow(Math.sin(delta_psi/2), 2) * Math.cos(psi1) * Math.cos(psi2) * Math.pow(Math.sin(delta_lambda/2), 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

        return c * R;
    }

    private static double criaAresta(int a, int b){
        float x1= coords.get(a)[0];
        float y1= coords.get(a)[1];
        float x2= coords.get(b)[0];
        float y2= coords.get(b)[1];

        return distance(x1,y1,x2,y2);
    }


    public static void main(String args[]) throws IOException {

        File processado = new File("infopross.pl");
        FileWriter escrita = new FileWriter("infopross.pl");

        File excel = new File("estacoes_metropolitano.xlsx");
        FileInputStream leitura = new FileInputStream(excel);

        escrita.write( "%                         ---Predicados---\n:-dynamic paragem/7.\n" +
                ":-dynamic linha/2.\n" +
                ":-dynamic aresta/3.\n" +
                ":-dynamic linhas/2.\n\n");

        XSSFWorkbook wb = new XSSFWorkbook(leitura);
        int num = wb.getNumberOfSheets();

        XSSFSheet folha = wb.getSheetAt(0);
        Iterator<Row> iterador = folha.iterator();  //iterador que irá percorrer as linhas da folha selecionada
        //Não é necessário ler a informação da primeira linha
        Row row = iterador.next();
        int i = 1; int cor = 0;

        escrita.write("\n%PARAGENS------------------------- - - - -  -  -  -    -\n\n");
        while (iterador.hasNext()) {
            row = iterador.next();
        //Tratamento de uma linha célula a célula
            Iterator<Cell> iteradorCel = row.cellIterator();
            int id = 0;
            float[] coordenadas = new float[2];
            //Escrita do Id da paragem
                Cell celula = iteradorCel.next();
                escrita.write("paragem( " + celula.toString() );
                id = Integer.parseInt(celula.toString());
            //Escrita do GIS_Id da paragem
                celula = iteradorCel.next();
                String[] numID = celula.toString().split("[a-zA-Z]*_");
                escrita.write(", "+ numID[1] + ",");
            //Escrita das Linhas da paragem, bem como organização das paragens por linhas
                celula = iteradorCel.next();
                String[] par = celula.toString().split("[ ]*,[ ]*");
                int l = par.length;
                escrita.write('[');
                for (int b = 0; b < l; b++) {
                    if (paragens.containsKey(par[b])) {
                        paragens.get(par[b]).add(i);
                    } else {
                        List<Integer> ids = new ArrayList<Integer>();
                        ids.add(i);
                        paragens.put(par[b], ids);
                        if (!linhas.containsValue(par[b])){
                            linhas.put(par[b],cor);
                            cor++;
                        }
                    }
                    if (b != l-1)
                        escrita.write( linhas.get(par[b]) + ", ");
                    else
                        escrita.write(linhas.get(par[b]) + "], ");
                }

            //Escrita e leitura da coordenada X da paragem
                celula = iteradorCel.next();
                escrita.write(celula.toString() + ", ");
                coordenadas[0] = Float.parseFloat(celula.toString());
            //Escrita e leitura da coordenada Y da paragem
                celula = iteradorCel.next();
                escrita.write(celula.toString() + ",");
                coordenadas[1] = Float.parseFloat(celula.toString());
            //Escrita da variavel binária que representa a presença de BILHETEIRA na paragem
                celula = iteradorCel.next();
                escrita.write(celula.toString() + ",");
            //Escrita da variavel binária que representa a presença de BAR na paragem
                celula = iteradorCel.next();
                escrita.write(celula.toString() + ").\n");

            i++;
            //Adiciona ao mapa das coordenadas as associadas ao Id da linha lida
            coords.put(id,coordenadas);
        }

        //Escrita da informação referente às linhas no ficheiro de output, com os Ids de paragens a que lhe pertencem
        escrita.write("\n\n%LINHAS--------------------------- - - - -  -  -  -    -\n\n");
        for (Map.Entry<String, List<Integer>> entry : paragens.entrySet()) {
            int c = linhas.get(entry.getKey());
            escrita.write("linha(" + c + "," + entry.getValue().toString() + ").\n");
        }

        //Criação e calculo das arestas
        for (Map.Entry<String, List<Integer>> entry : paragens.entrySet()){
            List<Integer> linha = entry.getValue();

            for ( int q = 0; q < linha.size()-1; q++){
                int primeiro = linha.get(q);
                int segundo = linha.get(q+1);
                double distancia = criaAresta(primeiro,segundo);
                Aresta novo1 = new Aresta(primeiro,segundo,distancia);
                Aresta novo2 = new Aresta(segundo,primeiro,distancia);
                if ( !arestas.contains(novo1)) arestas.add(novo1);
                if ( !arestas.contains(novo2)) arestas.add(novo2);
            }
        }

        //Escrita das arestas e respetiva distancia no ficheiro de output
        escrita.write("\n\n%ARESTAS--------------------------- - - - -  -  -  -    -\n\n");
        for (Aresta entry : arestas) {
            escrita.write("aresta(" + entry.inicio + ", " + entry.fim + ", " + entry.distance + ").\n");
        }

        //Escrita da relação entre as cores das linhas e o numero que a identifica
        escrita.write("\n\n%CORES DAS LINHAS--------------------------- - - - -  -  -  -    -\n\n");
        for (Map.Entry<String, Integer> entry : linhas.entrySet()) {
            escrita.write("linhas(" + entry.getKey() +", " + entry.getValue().toString() + ").\n");
        }

        escrita.flush();
        escrita.close();
        System.out.println("Folhas - " + num + "   Linhas - " + i + "   Cores de Linhas - " + paragens.size() + "\n");
        System.out.println("\nTotal de arestas criadas:  " + arestas.size());
    }
}
