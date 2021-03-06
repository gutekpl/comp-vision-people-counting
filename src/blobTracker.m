% *********************************************************************
%                                                                   
%   Funkcja: blobTracker                                     
%                                                                   
%   Przeznaczenie:                                                  
%       Funkcja �ledzi obiekty zlokalizowane na kolejnych klatkach filmu.
%       W ramach �ledzenia zostaj� w odpowiedni spos�b przeniesione do
%       obiekt�w z klatki aktualnej informacje o ilo�ci os�b stanowi�cych
%       obiekt w klatce poprzedniej.
%       Dzia�anie polega na przeanalizowaniu informacji z dw�ch kolejnych
%       klatek filmu. Celem jest skojarzenie obiekt�w z klatki aktualnej z
%       obiektami z klatki poprzedniej. Skojarzenie oznacza, �e s� to te
%       same, cz�ciowo przesuni�te obiekty.
%       Obiekty z dw�ch kolejnych klatek filmu zostaj�
%       uznane za ten sam, przemieszczaj�cy si� obiekt, 
%       je�eli znaczne ich cz�ci si� pokrywaj�.
%       Funkcja musi by� wywo�ywana po kolei, dla ka�dej klatki filmu, zaczynaj�c
%       od drugiej.

%   Argumenty funkcji:
%       X           - Macierz o wymiarach [m n] - aktualnie przetwarzana 
%                     klatka filmu, otrzymana po przetworzeniu i posegmentowaniu.
%                     Ka�dy obiekt jak i t�o musz� mie� inny odzie� szaro�ci.
%       Xprev       - Poprzednia klatka filmu o wymogach j.w.
%       grain       - Tablica stuktur zawieraj�cych informacje o ka�dym z
%                     obiekt�w znalezionych w aktualnej klatce. 
%                     Rozmiar tablicy odpowiada ilo�ci obiekt�w otrzymanych
%                     w wyniku segmentacji.
%       prevGrain   - Tablica struktur znalezionych w poprzedniej klatce.
%       config      - Struktura zawieraj�ce informacje konfigracyjne
%                     algorytmu zliczania os�b                       
%                                                                   
%   Funkcja zwraca:                                                 
%       newGraindata    - Tablica struktur zawieraj�cych informacje o ka�dym z obiekt�w znalezionych w aktualnej klatce.
%                         W odr�nieniu od zmiennej wej�ciowej "grain",
%                         "newGraindata" jest struktur� poszerzon� -
%                         zawiera szereg informacji dodatkowych
%       numOfDeadBubbles    - Ilo�� ludzi sk�adaj�cych si� na obiekty,
%                             kt�rych �ledzenie zosta�o
%                             zako�czone w aktualnej klatce. W praktyce jest to ilo�� os�b kt�ra
%                             w por�wnaniu do klatki poprzedniej zesz�a z pola widzenia
%                                                                   
%   Uzywane funkcje:                                                
%       blobTrackerGutek korzysta z podstawowych funkcji �rodowiska MatLab, 
%       g��wnie operuj�cych na macierzach i liczbach.                            
%                                                                   
%   Uzywane zmienne:                                                
%       m_wspolnosci    - "Macierz wsp�lno�ci", przechowuj�ca informacj� o tym w jakim
%                         stopniu obiekty z klatki aktualnej odpowiadaj� obiektom z klatki
%                         poprzedniej (nak�adaj� si�).
%                         Ka�dy wiersz odpowiada kolejnemu obiektowi z
%                         klatki poprzedniej, ka�da kolumna obiektowi z
%                         klatki aktualnej. Indeks wiersza/kolumny pokrywa
%                         si� z indeksem obiektu z klatki
%                         poprzedniej/aktualnej.
%                         Element o wsp�rz�dnych i,j jest liczb�
%                         okre�laj�c� wsp�ln� powierzchni� (wyra�on� w
%                         pikselach): i-tego obiektu z klatki poprzedniej,
%                         oraz j-tego obiektu z klatki aktualnej.
%       numOfPrevs      - Ilo�� obiekt�w na klatce poprzedniej
%                         (ilo�� wierszy macierzy "m_wspolnosci")
%       numOfActs       - Ilo�� obiekt�w na klatce aktualnej
%                         (ilo�� kolumn macierzy "m_wspolnosci")
%       newX            - Klatka (macierz) powsta�a z po��czania klatek X oraz prevX
%                         Warto�� ka�dego piksela jednoznacznie okre�la czy
%                         jest to:
%                         a) t�o w obrazie X oraz prevX
%                         b) tylko cz�� i-tego obiektu z prevX lub
%                            tylko cz�� j-tego obiektu z X
%                         c) jednocze�nie i-ty obiekt z prevX oraz j-ty
%                            obiekt z X (na�o�one obiekty)
%       koloryPrev      - Tablica zawieraj�ca liczby odpowiadaj�ce
%                         odcieniom szaro�ci kolejnych obiekt�w z poprzedniej klatki
%                         (d�ugo�� talbicy jest r�wna ilo�ci wierszy
%                         macierzy m_wspolnosci).
%                         Zmienna potrzebna do utworzenia "m_wspolnosci".
%       kolory          - Tablica zawieraj�ca liczby odpowiadaj�ce
%                         odcieniom szaro�ci kolejnych obiekt�w z aktualnej klatki
%                         (d�ugo�� talbicy jest r�wna ilo�ci kolumn
%                         macierzy m_wspolnosci).
%                         Zmienna potrzebna do utworzenia "m_wspolnosci".
%                                                                                              
%                                                                   
%   Autor:                                                          
%       Pawe� Gutowski
% 
%                                                                   
%   Ostatnia modyfikacja:                                           
%       07.01.2007 r.            
%                                                                   
% *********************************************************************


function [newGraindata, numOfDeadBubbles] = blobTrackerGutek( X, Xprev, grain, prevGrain, config)

% Inicjalizacja zmiennych
numOfDeadBubbles = 0;
numOfPrevs = size(prevGrain);
numOfPrevs = numOfPrevs(1);
numOfActs = size(grain);
numOfActs = numOfActs(1);
m_wspolnosci = zeros(numOfPrevs,numOfActs );
newX = uint32(256*uint32(X) + uint32(Xprev));

% Inicjalizacja tablic koloryPrev oraz kolory
for i = 1:numOfPrevs
    lista = prevGrain(i).PixelList;
    wsp = lista(1,:);
    koloryPrev(i) = uint32(Xprev(wsp(2), wsp(1)));
end
for i = 1:numOfActs
    lista = grain(i).PixelList;
    wsp = lista(1,:);
    kolory(i) = uint32(X(wsp(2), wsp(1)));
end

% Tworzymy macierz m_wspolnosci.
% Uzywamy do tego stworzonych wczesniej zmiennych:
% kolory, koloryPrev, newX
for i = 1:numOfPrevs     %dla ka�dego b�bla z poprzredniej klatki
    for j = 1:numOfActs    %z ka�dym b�blem z tej klatki
        count = size(find(newX == 256*kolory(j) + koloryPrev(i)));
        count = count(1);
        m_wspolnosci(i, j) = count;
    end
end

%Dwie poni�sze p�tle s� odpowiedzialne za "inteligentne" przeniesienie
%informacji z klatki poprzedniej do klatki aktualnej.
%Je�eli np dwa obiekty si� po��czy�y w jeden, to wiadomo, �e na nowy obiekt
%sk�ada si� dwoje �ledzonych ludzi.

%Zerujemy ilo�� ludzi w b�blach otrzyman� od b�bli z poprzedniej klatki
for i=1:numOfActs
    grain(i).numOfPeople = double(0);
    grain(i).age = double(0);
end

% Rozdzielamy ludzi sk�adaj�cych si� na obiekty z klatki poprzedniej
% pomi�dzy obiekty z klatki aktualnej
% Ilo�� "prekazywanych" ludzi jest proporcjonalna do powierzchni pokrycia z
% nowym obiektem.
for i=1:numOfPrevs
    sumWspolnosci = sum(m_wspolnosci(i,:)');
    numOfPeopleToGive = prevGrain(i).numOfPeople;
    if sumWspolnosci > 0           %czyli, ze stary b�bel ma komu przekaza� swoich ludzi
        for j=1:numOfActs
            if sumWspolnosci > 0
                k_float =  (numOfPeopleToGive * m_wspolnosci(i,j)) / sumWspolnosci;     %ilosc ludzi, ktora wraz z bablem przeszla do innego babla
                k = int32(k_float); 
                grain(j).numOfPeople = double(grain(j).numOfPeople + k);            %zwiekszamy ilosc ludzi w nowotowrzonym b�blu
                sumWspolnosci = sumWspolnosci - m_wspolnosci(i,j);
                numOfPeopleToGive = numOfPeopleToGive - k;                  %skoro z babla "j" przekazano "k" ludzi do b�bla "i", to do rozdysponowania mamy o "k" ludzi mniej
                if k > 0                                                    %Je�eli do nowego b�bla zosta�a przekazana niezerowa ilo�� os�b, to znaczy, �e ten b�bel ma czas �ycia taki, jak najstarszy z jego 'potomk�w'
                    grain(j).age = max(grain(j).age, prevGrain(i).age);
                end
            end
        end 
    else                %b�bel ginie [czy tak?]
        if prevGrain(i).age >= config.minAge            %jezeli wlasnie umierajacy b�bel pojawi� si� na filmie d�u�ej ni� minimalna ilo�� klatek
            numOfDeadBubbles = numOfDeadBubbles + uint8(config.wagaPrzenikania * prevGrain(i).numOfPeople...
                                                + config.wagaKsztaltu * prevGrain(i).AverageNumOfPeopleShape...
                                                + config.wagaPola * prevGrain(i).AverageNumOfPeopleArea);
        end
    end
end

%je�eli jakis nowy b�bel nie dosta� w spadku ani jednego cz�owieka, to
%znaczy, �e dopiero powsta�, wi�c niesie w sobie przynajmniej jednego
%cz�owieka
for i=1:numOfActs
    
    if grain(i).numOfPeople == 0
        grain(i).numOfPeople = 1;
    end 
    grain(i).age = grain(i).age + 1;   %inkrementujemy czas �ycia b�bla  
end

% W tej p�tli poszerzamy struktury odpowiadaj�ce obiektom z aktualnej
% klatki o informacje wydobyte z zale�no�ci mi�dzy dwoma kolejnymi
% klatkami.
% Struktury te s� pozamykane w tablicy "grain"
for i = 1:numOfActs
    id = i;
    prevId = find(m_wspolnosci(:,i));
    [numS, numA] = shapeCoef(grain(i), config);
    if grain(i).age == 1            % babel dopiero powstal
        AvCnt = 0;
        newAverageNumOfPeopleShape = numS;
        newAverageNumOfPeopleArea = numA; 
    else                            % babel istnial juz jakis czas
        % bierzemy i uzywamy prevID(1), bo jesli tutaj doszlismy, to znaczy, ze istnieje 1-szy element. Jezeli jest wiecej niz 1 elementow, to i tak zostanie to zweryfikowane w kolejnej petli
        AvCnt = prevGrain(prevId(1)).AverageCnt;
        %prevId(1)
        newAverageNumOfPeopleShape = (AvCnt * prevGrain(prevId(1)).AverageNumOfPeopleShape + numS) / (AvCnt + 1);   % wyliczanie nowych �rednich warto�ci odpowiedzi z metod wsp�czynnikowej i na pole
        newAverageNumOfPeopleArea  = (AvCnt * prevGrain(prevId(1)).AverageNumOfPeopleArea  + numA) / (AvCnt + 1);   
    end
    AvCnt = AvCnt + 1;
    grain(i).ID = id;      %czyli to samo co 'i'
    grain(i).PrevID = prevId;
    grain(i).numOfPeopleShape = numS;
    grain(i).numOfPeopleArea = numA;
    grain(i).AverageCnt = AvCnt;
    grain(i).AverageNumOfPeopleShape = newAverageNumOfPeopleShape;
    grain(i).AverageNumOfPeopleArea  = newAverageNumOfPeopleArea;
end

%sprawdzamy dla kazdego babla czy w tej klatce nast�pi� dla niego "moment krytyczny" def. w
%dokumentacji
for i = 1:numOfActs
    prevId = find(m_wspolnosci(:,i));
    if length(prevId) > 1   %aktualny obiekt powstal jako sklejenie kliku obiktow, wiec nastapil "moment krytyczny"
         grain(i).AverageCnt = 0;
         grain(i).AverageNumOfPeopleShape = grain(i).numOfPeopleShape;
         grain(i).AverageNumOfPeopleArea = grain(i).numOfPeopleArea;
    else
        %aktualny obietk nie powstal jako sklejenie przynajmniej dwoch obiektow, wiec
        %sprawdzamy czy jego poprzednik sie podzielil
        for z = 1: length(grain(i).PrevID)
            cnt = 0;
            for k = 1: length(grain)
                for j = 1:length(grain(k).PrevID)
                    if grain(i).PrevID(z) == grain(k).PrevID(j)
                        cnt = cnt +1;
                    end
                end
            end
            if cnt > 1  %obiekt o ID=i powsta� z b�bla, kt�ry si� podzieli�
                grain(i).AverageCnt = 0;
                grain(i).AverageNumOfPeopleShape = grain(i).numOfPeopleShape;
                grain(i).AverageNumOfPeopleArea = grain(i).numOfPeopleArea;
            end
        end
    end
end

newGraindata = grain;
