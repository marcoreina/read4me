require 'rubygems'
require 'hornetseye_v4l2'
require 'hornetseye_xorg'
require 'hornetseye_rmagick'
require 'nokogiri'
include Hornetseye

class OCR
  #*************************#
  #Constantes               #
  #*************************#

  #Define a largura/altura da matriz de entrada para a rede neural
  DimensaoEntrada = 10
  CorLimite = 128
  
  #*************************#
  #Variáveis                #
  #*************************#
  #Variável que referencia o arquivo de letras aprendidas 
  @letraAprendida = nil
  
  #*************************#
  #Métodos                  #
  #*************************#
  
  def initialize()
    #Inicia testando se o arquivo XML que armazena os caracteres aprendidos já existe ou precisa ser recriado
    if not FileTest.exist? "Fontes/Fontes.xml"
      #Se não existe, crio o arquivo XML inicialmente vazio
      criaXML()
    else
      f = File.open('Fontes/Fontes.xml', 'r')
      doc = Nokogiri::XML(f)
      dimensao = doc.xpath('//baseConhecimento/@dimensaoEntrada')[0].value.to_i
      f.close
      #Se a dimensão que foi gravada no XML é diferente da dimensão atual, refaço o arquivo XML
      if dimensao != DimensaoEntrada
        criaXML()
      end
    end
    treinamento()
  end
#*****************************************************
  
  #Método que cria o arquivo XML que armazena os caracteres aprendidos
  def criaXML()
    strXML = "<ocr><fontes/><baseConhecimento dimensaoEntrada='#{DimensaoEntrada}'>"
    for i in "A"[0].."Z"[0]
      strXML += "<elemento caracter='#{i.chr}'>"
      for i in 0..DimensaoEntrada-1
        strXML += "<linhas_#{i}></linhas_#{i}>"
      end
      strXML +="</elemento>"
    end
    for i in "a"[0].."z"[0]
      strXML += "<elemento caracter='#{i.chr}'>"
      for i in 0..DimensaoEntrada-1
        strXML += "<linhas_#{i}></linhas_#{i}>"
      end
      strXML +="</elemento>"
    end
    strXML += "</baseConhecimento></ocr>"
    
    arquivo = File.open('Fontes/Fontes.xml', 'w')
    xml = Nokogiri::XML(strXML)
    arquivo.puts xml.to_xml
    arquivo.close
  end
#*****************************************************

  #Método que faz o treinamento da rede neural
  def treinamento()
    arquivo = File.open('Fontes/Fontes.xml', 'r')
    xml = Nokogiri::XML(arquivo)
    arquivo.close
    fontesAprendidas = Array.new
    xmlFontes = xml.xpath('//fontes/fonte')
    xmlFontes.each {|fonte|
      fontesAprendidas.push fonte.content
    }
    #Vai no diretório 'Fontes' e pega todos os arquivos '.jpg' que contém as fontes para servirem de treinamento
    fontes = Dir["Fontes/*.jpg"]
    for i in 0..fontes.length-1
      fonte = fontes[i]
      #Só faço os cálculos caso a fonte ainda não tenha sido aprendida
      if not fontesAprendidas.include? fonte
        #Neste caso é uma fonte nova que terá que ser aprendida
        letras = Array.new
        letras_temp = Array.new
        img = MultiArray.load_ubyte fonte
        #Encontra linha por linha
        linhas = encontraLinha img
        #Para cada linha, encontra as letras
        linhas.each { |l| letras_temp.push encontraLetra l }
        letras_temp.each {|l| letras += l }
        for i in 0..letras.length-1
          letras[i] = preparaLetra letras[i]
        end
        
        aprendeLetra(letras, fonte)
      end
    end
    inicializaLetraAprendida()
  end
#*****************************************************

  #Método que coloca em memória o arquivo final de caracteres aprendidos
  def inicializaLetraAprendida()
    arquivo = File.open('Fontes/Fontes.xml', 'r')
    @letraAprendida = Nokogiri::XML(arquivo)
    arquivo.close
  end
#*****************************************************

  #Método que recebe a imagem do papel que contém o texto e retorna uma array com as linhas do texto
  def encontraLinha(img)
    linhas = Array.new
    y = lazy( *img.shape ) { |i,j| j }
    componentes = (img <= CorLimite).components
    num_componentes = componentes.max
    alturaMedia = 0.0
    numMedioPixel = 0.0
    nComponente = 0
    
    #Faço um histograma para saber quantos pixels cada componente conexo tem
    histograma = componentes.histogram num_componentes+1
    
    #A partir do histograma, calculo uma media de pixels
    for i in 1..histograma.width-1
      numMedioPixel += histograma[i]
    end
    numMedioPixel = numMedioPixel/histograma.width-1
    
    #Descarto componentes que são muito pequenos (possivelmente lixo), menores que 5% de um caracter
    mascara = histograma.between? 0, (numMedioPixel*0.05).round
    
    #Sequencia de componentes que sao lixos e serão descartados
    componenteLixo = Sequence( INT, num_componentes+1 ).indgen.mask(mascara).to_a
    
    #Coloco a label de todos esses componentes como "zero", para mais a frente ser descartado junto com o fundo do papel
    componenteLixo.each do |c|
      componente = componentes.eq c
      componente = componente.conditional(-c,0)
      componentes += componente
    end
    
    #Aqui obtenho novamente os componentes, desta vez já limpo de lixos e ruídos
    componentes = componentes.components
    num_componentes = componentes.max
    
    #Faço uma amostragem, pegando a média da altura de componentes conexos aleatórios
    for i in 1..componentes.max-1
      caracter = componentes.eq i
      topo = y.mask( caracter ).range.min
      pe = y.mask( caracter ).range.max
      alturaMedia += pe - topo
    end
    alturaMedia = alturaMedia / num_componentes
    
    while nComponente != num_componentes
      linha = nil
      linhaTopo, linhaPe = nil,nil
      blnEncontreiLetra = false
      #Primeiro componentes da linha
      componenteInicial = nComponente + 1
      
      begin
        nComponente += 1
        caracter = componentes.eq nComponente
        topoCaracter = y.mask( caracter ).range.min
        peCaracter = y.mask( caracter ).range.max
        alturaCaracter = peCaracter - topoCaracter
        
        #Teste para saber se o que acabamos de encontrar já é elemento da próxima linha,
        #isto é, se é um acento da próxima linha, abaixo da linha atual, supondo que somente os
        #acentos podem acabar invadindo a região de outra linha. 
        if blnEncontreiLetra == true
          if alturaCaracter < alturaMedia * 0.5 and peCaracter > linhaPe
            nComponente -= 1
            break
          end
        else
          blnEncontreiLetra = alturaCaracter > alturaMedia * 0.5
        end
        
        linhaTopo = topoCaracter if linhaTopo.nil? or topoCaracter < linhaTopo 
        linhaPe = peCaracter if linhaPe.nil? or peCaracter > linhaPe
        #linha = componentes[0..componentes.width-1, linhaTopo..linhaPe]
        linha = componentes[0..componentes.width-1, linhaTopo..linhaPe]
      end while nComponente != linha.max or blnEncontreiLetra == false
      
      #Descarta todos os componentes que já foram processados
      linha = (linha < componenteInicial).conditional(nComponente + 1, 0) + linha
      linha = (linha < nComponente + 1).conditional(0,255)
      
      linhas.push linha
    end
    linhas
  end
#*****************************************************
 
  #Método que recebe uma linha do texto e retorna uma array com as letras
  def encontraLetra(linha)
    #Coloco a linha na vertical, dessa forma a ordem dos componentes coincide com a ordem das letras
    letrasEncontradas = Array.new
    linha = linha.to_magick.rotate(90).to_ubyte
    x = lazy( *linha.shape ) { |i,j| i }
    y = lazy( *linha.shape ) { |i,j| j }
    componentes = (linha <= CorLimite).components
    labelLetraAnterior = nil
    espacoMedio = 0.0
    
    #Esse primeiro loop coloca acentos como mesmo componentes da letra a que pertencem
    for nComponente in 1..componentes.range.max
      letra = componentes.eq nComponente
      alturaLetra = x.mask(letra).range
      larguraLetra = y.mask(letra).range
      componenteMaximo = componentes[0..letra.width-1, larguraLetra].max
      #Se existe um outro componente na faixa da largura da letra em questão, então mescla
      if(componenteMaximo != nComponente)
        componentes[0..letra.width-1, larguraLetra] += letra[0..letra.width-1, larguraLetra].conditional(componenteMaximo - nComponente,0)
      else
        box = [ alturaLetra, larguraLetra ]
        letrasEncontradas.push linha[*box].to_magick.rotate(-90).to_ubyte
        
        #Calcula o espaçamento entre uma letra e outra 
        if not labelLetraAnterior.nil?
          letraAnterior = componentes.eq labelLetraAnterior
          posLetraAnterior = y.mask(letraAnterior).range.max
          espacoMedio += larguraLetra.min - posLetraAnterior
        end
        labelLetraAnterior = nComponente
      end
    end
    
    espacoMedio = espacoMedio / letrasEncontradas.length - 1
    
    
    letrasEncontradas
  end
#*****************************************************

  #Método que recebe uma letra e redimensiona para que a letra se ajuste ao tamanho da entrada para a rede neural
  def preparaLetra(letra)
    #Define o fator para não distorcer a letra 
    fatorEscala = letra.width > letra.height ? DimensaoEntrada.to_f/letra.width : DimensaoEntrada.to_f/letra.height
    letra = letra.to_magick
    letra = letra.scale(fatorEscala)
    letra = letra.to_ubyte
    
    letra = (letra < 192).conditional(0,255)
    
    #Verificando se a letra está bem ajustada, sem colunas em branco à esquerda
    #blnLetraOk = false
    #primeiraColuna = (MultiArray.ubyte 1, letra.height).fill! 255
    #y = lazy( *primeiraColuna.shape ) { |i,j| j }
    #intervaloPrimeiraColuna = [ 0, y.mask( primeiraColuna ).range ]
    
    #while blnLetraOk == false
      #mascara = (letra[*intervaloPrimeiraColuna] < 255)
      #indicePixel = Sequence( INT, letra.height ).indgen.mask(mascara).to_a
      
      #if (indicePixel.length == 1) or (indicePixel.length == 2 and indicePixel[1] - indicePixel[0] > 1) or (indicePixel.length == 4 and indicePixel[0] == 0 and indicePixel[1] == 1 and indicePixel[2] == letra.height-2 and indicePixel[3] == letra.height-1)
        #letra = letra[1..letra.width-1,0..letra.height-1]
      #else
        #blnLetraOk = true
      #end
    #end
    resultado = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill! 255
    resultado[0..letra.width-1, 0..letra.height-1] = letra
    resultado
  end
 
#*****************************************************
  
  #Método que dada a matriz do caracter, passa os valores dos dos elementos para uma string e salva no arquivo XML
  def saveCaracterXML(caracter, matrizCaracter)
    matrizBinaria = ( matrizCaracter <= CorLimite).conditional(1,0)
    
    arquivo = File.open('Fontes/Fontes.xml', 'r')
    xml = Nokogiri::XML(arquivo)
    arquivo.close
    
    for i in 0..matrizBinaria.height-1
      linha = matrizBinaria[0..matrizBinaria.width-1, i]
      mapeamentoBinario = linha.to_a.join
      teste = xml.xpath("//baseConhecimento/elemento[@caracter = '#{caracter}']/linhas_#{i}/linha[. = '#{mapeamentoBinario}']")
      if teste.length == 0
        fontesNode = xml.xpath("//baseConhecimento/elemento[@caracter = '#{caracter}']/linhas_#{i}")
        fonteXML = Nokogiri::XML::Node.new "linha", xml
        fonteXML.content = mapeamentoBinario
        fontesNode[0].add_child fonteXML
      end
    end
    
    arquivo = File.open('Fontes/Fontes.xml', 'w')
    arquivo.puts xml.to_xml
    arquivo.close
  end
  
#*****************************************************

  #Método que recebe os caracteres e os salva no arquivo XML
  def aprendeLetra(letras, fonte)
    #Adiciono a nova fonte a ser aprendida no XML
    arquivo = File.open('Fontes/Fontes.xml', 'r')
    xml = Nokogiri::XML(arquivo)
    arquivo.close
    fontesNode = xml.xpath('//fontes')
    fonteXML = Nokogiri::XML::Node.new "fonte", xml
    fonteXML.content = fonte
    fontesNode[0].add_child fonteXML
    arquivo = File.open('Fontes/Fontes.xml', 'w')
    arquivo.puts xml.to_xml
    arquivo.close
    
    letras.reverse!
    
    for i in "A"[0].."Z"[0]
      saveCaracterXML( i.chr, letras.pop)
    end
    for i in "a"[0].."z"[0]
      saveCaracterXML( i.chr, letras.pop)
    end
  end
 
#*****************************************************

  #Método que, dado o caracter, tenta reconhece-lo
  def reconheca(entrada)
    entrada = (entrada <= CorLimite).conditional(1,0)
    total = Array.new
    DimensaoEntrada.times {total.push []}
    
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      temp = @letraAprendida.xpath("//baseConhecimento/elemento[linhas_#{i}/linha[. = '#{mapeamentoBinario}']]/@caracter")
      temp.each {|e| total[i].push e.content}
    end
    total.flatten!
    caracter = total.uniq
    vezes = []
    caracter.each {|e| vezes.push total.count(e)}
    resultado = caracter[vezes.index(vezes.max)]
    coeficienteReconhecimento = (total.count resultado)/DimensaoEntrada.to_f
    return resultado, coeficienteReconhecimento
  end

#*****************************************************

  #Método que após aprendizado, é chamado para identificar o texto
  def le(img)
    letras = Array.new
    letras_temp = Array.new
    letrasReconhecidas = Array.new
    #Encontra linha por linha
    linhas = encontraLinha img
    #Para cada linha, encontra as letras
    linhas.each { |l| letras_temp.push encontraLetra l }
    letras_temp.each {|l| letras += l }
    
    for i in 0..letras.length-1
      letrasReconhecidas.push reconheca preparaLetra letras[i]
    end
    letrasReconhecidas
  end
end