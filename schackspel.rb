#Schackspel.rb
#Namn: Oliver Nyström
#Datum: 2025-02-18
#Schackspel

require 'ruby2d'

#Fönsterinställningar (Ruby 2D inställningar)
set width: 600, height: 600, background: 'white', title: 'Schackspel'

class ChessBoard
  attr_accessor :board, :tile_size, :current_turn, :selected_piece #attr skapar getter setter funktioner så vi slipper skapa egna getter setter funktioner för alla variabler, getter returnerar setter tilldelar
  #minnesregel: vi behöver ändast passera in argument och parametrar som människan/spelaren påverkar, ENDAST EXTERN DATA!!!

  #initierar ett nytt schackbräde, sätter upp pjäser och ritar ut brädet. inga parametrar

  def initialize
    @board = Array.new(8) { Array.new(8, nil) }
    @tile_size = 75 # Storlek på varje ruta i pixlar
    @current_turn = 'white' # Vita börjar
    @selected_piece = nil # Håller koll på vald pjäs
    setup_pieces #Sätt upp pjäser
    draw_board #Rita brädet som sen ritar pjäser
  end

  # Placerar ut shackpjäserna på sina startpositioner, inga parametrar, inga returvärden (ändrar bara brädets tillstånd)

  def setup_pieces
    @board[0] = ['R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R']#Svarta pjäser
    @board[1] = Array.new(8, 'P')# Svarta bönder
    @board[6] = Array.new(8, 'p')# Vita bönder
    @board[7] = ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r']#Vita pjäser
  end

  # ritar ut schackbrädet, inga parametrar, inga returvärden (ritar direkt i fönstret)

  def draw_board
    # Rensa skärmen
    Window.clear

    # Rita schackbrädet
    8.times do |row|
      8.times do |col|
        color = (row + col).even? ? 'yellow' : 'brown'
        Square.new(
          x: col * @tile_size, 
          y: row * @tile_size, 
          size: @tile_size, 
          color: color
        )
      end
    end
    draw_pieces
  end

  #ritar ut pjäserna

  def draw_pieces
    # Visa pjäserna på brädet
    @board.each_with_index do |row, row_index|
      row.each_with_index do |cell, col_index|
        next if cell.nil?

        piece_color = cell == cell.upcase ? 'black' : 'white' #svarta = stora bokstäver, vita = små bokstäver
        Text.new(
          cell,
          x: col_index * @tile_size + @tile_size / 3,
          y: row_index * @tile_size + @tile_size / 4,
          size: 30,
          color: piece_color
        )
      end
    end
  end

  # hanterar ett musklick genom att konvertera pixelkoordinater till rutor på mitt brädee, väljer antingen en pjäs eller genomför ett drag

  def handle_click(x, y)

    row, col = pixel_to_grid(x, y) #om vi passerar in x=80 och y=100 i funktionen handle_click så konverterar vi nu dessa kordinater till row och col mha funktionen pixel_to_grid
    if @selected_piece.nil?
      select_piece(row, col)
    else
      move_piece(@selected_piece, [row, col])
      @selected_piece = nil
    end
  end
  
  #väljer en pjäs baserat på rad och kolumn om den tillhör spelaren vars tur det är, parametrar: row = radindex för vald ruta, col = kolumnindex för vald ruta, inget returvärde (uppdaterar @selected_piece)

  def select_piece(row, col)
    piece = @board[row][col] #board [0][0] = a1 
    if piece && piece_color(piece) == @current_turn
      @selected_piece = [row, col]
      puts "Vald pjäs: #{@board[row][col]} på #{grid_to_position(row, col)}"
    else
      puts "Ingen giltig pjäs vald."
    end
  end

  #Utför ett drag från starttposition till en målposition om draget är gilltigt samt uppdaterar brädet och växlar tur. parametrar: array [rad, kolumn] för startpositionen, array [rad, kolumn] för målpositionen, inga returvärden men ändrar spelets tillstånd

  def move_piece(from, to)
    if valid_move?(from, to) && !move_puts_in_check?(from, to, @current_turn) && piece_color(@board[to[0]][to[1]]) != @current_turn
      from_row, from_col = from
      to_row, to_col = to
      @board[to_row][to_col] = @board[from_row][from_col]
      @board[from_row][from_col] = nil
      draw_board
      if checkmate?(@current_turn == 'white' ? 'black' : 'white')
        puts "Schackmatt! #{@current_turn.capitalize} vinner spelet."
        exit
      end
      @current_turn = @current_turn == 'white' ? 'black' : 'white' # Växla tur
    else
      puts "Olagligt drag eller kungen är hotad!"
      @selected_piece = nil
    end    
  end

  #Konverterar pixelkoordinater till motssvarande rad och column på brädet. parametrar: x = x-koordinat (pixlar), y = y-koordinat (pixlar), retunvärde: En array med [rad, kolumn]

  def pixel_to_grid(x, y)
    row = (y / @tile_size).to_i#@title_size=75 om y=300 => 300 delat på 75 = 4 = rad 4
    col = (x / @tile_size).to_i#samma
    [row, col]
  end

  #konverterar rad -och kolumnindex till schacknotation (t.ex "a1"). parametrar: radindex, kolumnindex, returnvärde: en sträng med positionen i schacknotation. 

  def grid_to_position(row, col)
    "#{(col + 'a'.ord).chr}#{8 - row}" #taget från internet skit i att lära dig detta just nu
  end

  #hittar positionen för kungen för angiven färg. parametrar: color = en sträng ('white' elr 'black'). returvärde: En array [rad, kolumn] för kungens position, eller då nil om den inte hittas

  def king_position(color)
    @board.each_with_index do |row, row_index| #row = array med celler (8st celler), row index = vilken rad och col index = vilken kolumn, cell = bokstav
      row.each_with_index do |cell, col_index|
        return [row_index, col_index] if cell == (color == 'white' ? 'k' : 'K')
      end
    end
    nil
  end

  #Kollar om kungen för angiven färg är i schack. parametrar: color = sträng 'white' / 'black'. returvärde: , en bool, true om kungen är i schack, false om inte
  def in_check?(color)
    king_pos = king_position(color)#hämta kungens position
    return false if king_pos.nil?#returnera false om kungen inte hittades
  
    opponent_color = color == 'white' ? 'black' : 'white'#för lättare kod
  
    @board.each_with_index do |row, row_index|#går igenom varje ruta på brädet
      row.each_with_index do |cell, col_index|##går igenom varje ruta på brädet
        next if cell.nil? || piece_color(cell) != opponent_color#hoppa over om cellen är tom eller inte tillhör motståndaren
        return true if valid_move?([row_index, col_index], king_pos, moving_color: opponent_color, ignore_check: true)#retyrnera true om det är ett giltigt drag från motståndarens pjäs (som är row index col index) till kungens position (king_pos), ignorera om det lämnar motståndaren i check det bryr vi oss inte om just nu
      end
    end
    false
  end

  #Kollar om spelaren för angiven färg är i schackmatt. parametrar: color sträng 'white' 'black'. returvärde: en bool, true om schackmatt, annars false, spelet avslutas om schackmatt.
  def checkmate?(color)
    return false unless in_check?(color) # Inte schack? Då inte schackmatt
  
    @board.each_with_index do |row, row_index|#går igenom varje ruta på brädet
      row.each_with_index do |cell, col_index|#går igenom varje ruta på brädet
        next if cell.nil? || piece_color(cell) != color#hoppa over om cellen är tom eller inte tillhör den aktuella spelaren
        8.times do |to_row|#testa alla möjliga destinationer(testa alla 64 rutor) för just den pjäsen och se om det finns något lagligt drag
          8.times do |to_col|#testa alla möjliga destinationer(testa alla 64 rutor) för just den pjäsen och se om det finns något lagligt drag
            if valid_move?([row_index, col_index], [to_row, to_col], moving_color: color) &&
               !move_puts_in_check?([row_index, col_index], [to_row, to_col], color)#är det ett valid move att flytta hit till dit? och kommer det movet sätta den aktuella spelarens kung i schack?
              return false # Finns ett drag som räddar kungen
            end
          end
        end
      end
    end
      winner = @current_turn == 'white' ? 'black' : 'white'
      puts "Checkmate! #{winner.capitalize} wins."
      Window.close
  end
  
  #kollar om ett föreslaget drag skulle sätta spelarens egen kung i schack. parametrar: startposition = array [rad, kolumn], målposition, spelarens färg ('white' elr 'black'). returnvärde: en bool, true om draget resulterar i schack, annars false
  def move_puts_in_check?(from, to, color)#from = array, to = array och color = string
    backup_board = Marshal.load(Marshal.dump(@board)) #skapa en kopia av brädet
  
    #gör ett tillfälligt drag som vi kan passera in i in_check? funktionen:
    piece = @board[from[0]][from[1]] #hämtar pjäsen
    @board[to[0]][to[1]] = piece #flyttar pjäsen
    @board[from[0]][from[1]] = nil #tömmer startplatsen 
  
    result = in_check?(color) #in_check? funktionen kollar om det tillfälliga brädet lämnar vit/svart kung i schack, result blir true eller false
  
    @board = backup_board #återställ brädet
    result
  end
  
  #bestämmer färgen på en given pjäs. parametrar: piece = en sträng som representerar pjäsen (stor bokstav = svart pjäa, liten bokstav = vit). returnvärde: 'black', 'white' eller nil om tom ruta
  def piece_color(piece)
    return nil if piece.nil?
    piece == piece.upcase ? 'black' : 'white'
  end

  #avgör om ett föreslaget drag är tillåtet baserat på pjäsen och spelets regler. parametrar: from = startposition, to = målposition, moving_color = färgen på spelaren som gör draget standard är färgen i @current_turn, ignore_chack = om true så ignoreras kontrollen schack standard är false. returvärde: true om draget är giltigt, annars false
  def valid_move?(from, to, moving_color: @current_turn, ignore_check: false) 
    #vi kan använda @current_turn istället för moving_color då det redan är en string men detta gör koden mer läsbar samt flexibel(liten onödigt kanske)
    #ignore_check sätts endast till true i en annan funktion om det är så att draget som spelaren vill göra kommer leda till att deras kung blir i shack, när den är sätt till true så sätts draget till false i denna funktionen
    return false if from == to #om du försöker flytta en pjäs till samma ruta som den redan står på är det inget giltigt drag, därför returnas false => valid_move?(from, to) = false => move_piece funktionen kallas inte
    
    from_row, from_col = from #delar in de inmatande positionerna i rad och kolumnvärden, om from = [6,3] => from_row = 6 och from_col = 3
    to_row, to_col = to
    return false if from_row.nil? || from_col.nil? || to_row.nil? || to_col.nil?#om du försöker flytta en pjäs till en kordinat som saknas dvs är nil är det inget gitligt drag, därför returnas false
  
    piece = @board[from_row][from_col] #@board = tvådimensionell arra (en array som består av två arrays), om from=[6,0] => @board[6][0] = p (står för pawm) = piece
    return false if piece.nil? #om piece blir nil innebär det att du försöker flytta en pjäs som inte finns, därför returneras false
    return false if !ignore_check && piece_color(piece) != moving_color # Om ignore_check är false (vilket betyder att vi gör ett riktigt drag) och pjäsen du försöker flytta inte tillhör den spelare vars tur det är, så är draget ogiltigt och vi returnerar false.
  
    if @board[to_row][to_col] && piece_color(@board[to_row][to_col]) == moving_color
      return false
    end

    case piece.downcase #case används för att endast anropa den funktion som bokstaven som piece är lika med 
    when 'p' then valid_pawn_move?(from, to, piece)
    when 'r' then valid_rook_move?(from, to)
    when 'n' then valid_knight_move?(from, to)
    when 'b' then valid_bishop_move?(from, to)
    when 'q' then valid_queen_move?(from, to)
    when 'k' then valid_king_move?(from, to)
    else
      false
    end
  end
  
  #Implementera pjäsernas specifika regler här (valid_pawn_move?, valid_rook_move?osv...)

  #kollar att det inte finns några pjäser mellan start- och målpositionen. parametrar: from = startpositionen, to = målpositionen. returvärde: true om vägen är fri, annars false
  def clear_path?(from, to)
    from_row, from_col = from #ex [2,3]
    to_row, to_col = to #ex [5.3]

    row_step = (to_row - from_row) <=> 0 # <=> ger 1 om positivt 0 om 0 och -1 om negativt, 5-2=3=>1
    col_step = (to_col - from_col) <=> 0 # 3-3=0=>0

    current_row, current_col = from_row + row_step, from_col + col_step #2+1=3, 3+0=3 => 3, 3
    while [current_row, current_col] != [to_row, to_col] # 3, 3 != 5, 3
      return false unless @board[current_row][current_col].nil? # om [3, 3] != nil dvs är upptagen => return false, om [3, 3] = nil dvs är tom => return true
      current_row += row_step # 3+1=4
      current_col += col_step # 3+0=3
      #loopen fortsätter tills vi upptäcker en ruta som inte är tom eller tills vi har nått målpositionen (to([5,3]), om vi uppnår målpositionen så har vi en clear path => returnerar true
    end
    true
  end

  #avgör om ett drag med en bonde är tillåtet, enda specifika funktionen som behöver piece som parameter eftersom vit endast får röra sig uppåt och svart nedåt 
  def valid_pawn_move?(from, to, piece)
    from_row, from_col = from
    to_row, to_col = to

    direction = piece == 'p' ? -1 : 1 #vit (-1) rör sig uppåt, svart (+1) nedåt
    start_row = piece == 'p' ? 6 : 1 #startposition för vit/svart

    if from_col == to_col #framåt (samma kolumn)
      return true if @board[to_row][to_col].nil? && to_row == from_row + direction#om rutan är tom och man flyttar ett steg framåt => returnera true
      return true if @board[to_row][to_col].nil? && to_row == from_row + (2 * direction) && from_row == start_row#om rutan är tom och vi flyttar två steg framåt och bonden är på sin startposition => returnera true
    elsif (from_col - to_col).abs == 1 && to_row == from_row + direction && !@board[to_row][to_col].nil?# Diagonalt för att slå
      return true
    end
    false
  end

  #avgör om ett drag med en rook är tillåtet
  def valid_rook_move?(from, to)
    from_row, from_col = from
    to_row, to_col = to

    return false unless from_row == to_row || from_col == to_col #Endast raka linjer
    clear_path?(from, to) #Kontrollera att inget blockerar vägen
  end

  #avgör om ett drag med en löpare är tillåtet
  def valid_bishop_move?(from, to)
    from_row, from_col = from
    to_row, to_col = to

    return false unless (from_row - to_row).abs == (from_col - to_col).abs #Diagonalt, .abs för absoluttalet
    clear_path?(from, to) #Kontrollera att inget blockerar vägen
  end

  #avgör om ett drag med en drottning är tillåtet
  def valid_queen_move?(from, to)
    valid_rook_move?(from, to) || valid_bishop_move?(from, to) # Kombinerar torn och löpare
  end

  #avgör om ett drag med en kung är tillåtet
  def valid_king_move?(from, to) #[1,2], [1,5]
    from_row, from_col = from #1, 2
    to_row, to_col = to #1, 5

    row_diff = (from_row - to_row).abs #1-1.abs=0
    col_diff = (from_col - to_col).abs #2-5.abs=3

    target_piece = @board[to_row][to_col] #för lättare kod
    return false if target_piece && piece_color(target_piece) == piece_color(@board[from_row][from_col]) #returnera false om det finns en pjäs i to redan och om den pjäsen har samma färg som kungen, kollar redan i valid move så att samma färg inte kan ta samma färg men gör det här igen för annars förstår inte datorn när det är schackmatt

    # Kontrollera att kungen inte går till en ruta där den hamnar i schack
    backup_board = Marshal.load(Marshal.dump(@board))#skapa en kopia
    @board[to_row][to_col] = @board[from_row][from_col]#flytta kungen
    @board[from_row][from_col] = nil#ta bort kungen från gammal ruta

    in_check = in_check?(piece_color(@board[to_row][to_col]))#in_check? funktionen kollar om det tillfälliga brädet lämnar vit/svart kung i schack, result blir true eller false
    @board = backup_board#återställ brädet

    row_diff <= 1 && col_diff <= 1 && !in_check #0 < 1 men 3 > 1 => inte giltigt
end

  #avgör om ett drag med en häst är tillåtet
  def valid_knight_move?(from, to) #[1,2], [2,4]
    from_row, from_col = from #1, 2
    to_row, to_col = to#2, 4

    row_diff = (from_row - to_row).abs #1-2.abs=1
    col_diff = (from_col - to_col).abs#2-4.abs=2

    row_diff == 2 && col_diff == 1 || row_diff == 1 && col_diff == 2#true
  end
end

# Skapa och visa brädet
board = ChessBoard.new

# Hantera mus-klick
on :mouse_down do |event|
  board.handle_click(event.x, event.y)
end

show
