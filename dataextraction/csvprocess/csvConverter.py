import PyPDF2 # python3 -m pip install SomePackage
import tabula # https://github.com/chezou/tabula-py
import re  # https://docs.python.org/3/howto/regex.html
from os import remove # Utilizado para remover archivos

#Alberto stuff modified a little bit by me.
def GetCSVFromPDF(pdf_file, directory_for_csv):
    file = open(pdf_file, 'rb')
    fileReader = PyPDF2.PdfFileReader(file)
    p = re.compile('\s+(?=-)') # Espacio antes de guión
    # https://stackoverflow.com/questions/3758798/how-to-search-for-occurrences-of-more-than-one-space-between-words-in-a-line/3758841
    q = re.compile('\s{2,}')  # Dos espacios o más
    # https://stackoverflow.com/questions/30317726/regex-to-select-a-space-between-two-digits
    r = re.compile('(?<=\d\s\d{3})\s') # Espacio después de miles
    # https://stackoverflow.com/questions/17027952/regex-for-all-spaces-before-a-number
    s = re.compile('\s(?=\d{1,3}\s\d{3})') # Espacios antes de miles
    t = re.compile(',+') # Elimina comas consecutivas
    u = re.compile('(?<=\d)\s(?=\d{3}(?!\d))') # Une miles separados por un espacio
    v = re.compile('^(?=\d{4})') # Selecciona el inicio de los años para agregar un salto de línea en ellos
    w = re.compile('\n(?!\d{4})') # Selecciona los saltos de línea que no siguen de un año
    x = re.compile('("",)+') # Estructura que a veces se lee en los encabezados: "",
    
    pages = []
    for pageNum in range(fileReader.numPages):
        csv_name="%s%s_%s.csv" % (directory_for_csv,
                                  pdf_file.split('/')[-1].split('.')[0],
                                  str(pageNum))
        pageObj = fileReader.getPage(pageNum)
        pageContent = str(pageObj.extractText().encode("utf-8"))
        if "CUADRO" in pageContent:
            headers = None
            # here in output path i need to put
            if "Aguascalientes" in pageContent:  # Si contiene información por estados
                tabula.convert_into(pdf_file, pages=pageNum, lattice=True, guess=True, output_format="csv", output_path="{}A.csv".format(pageNum))  # Se extrae un archivo con los encabezados correctos
            
                with open("{}A.csv".format(pageNum), "r") as f:
                    headers = f.readlines()
                    matching = None
                    for i in range(len(headers)):
                        if "Aguascalientes" in headers[i]:
                            matching = i
                            break
                        # https://stackoverflow.com/questions/46261294/remove-element-from-an-array-in-python3
                    del headers[i:]
                
                remove("{}A.csv".format(pageNum))
                        # split pdf_file name

                print("Building %s ... " % csv_name)
                tabula.convert_into(pdf_file, pages = pageNum, stream = True, guess = True, output_format = "csv", output_path = csv_name)
                pages.append(pageNum)
                content = None
                with open(csv_name, "r") as f: # https://www.digitalocean.com/community/tutorials/how-to-handle-plain-text-files-in-python-3
                    content = f.readlines()
            
                with open(csv_name, "w") as f:
                    if headers != None: # Si hay encabezados
                        for l in headers: 
                            l = v.sub('\n', l)
                            l = w.sub(' ', l) # Eliminar saltos de línea en líneas que no empiecen por los 20
                            l = x.sub('\n', l)
                            l = t.sub(',', l)
                            f.write(l) # Escribir los encabezados
                        f.write("\n")

                    estados = False # Booleana para definir el punto a partir del que hay información de estados en el archivo
                    for l in content:
                        if "Aguascalientes" in l:
                            estados = True
                        if estados:
                            l = p.sub(',', l)
                            l = q.sub(',', l)
                            l = r.sub(',', l, 1)
                            l = s.sub(',', l)
                            l = t.sub(',', l)
                            l = u.sub('', l)
                            if l[-1] is ',':
                                # Saltos de línea para corregir unión por miles
                                f.write(l + "\n")
                            else:
                                f.write(l)
                        
