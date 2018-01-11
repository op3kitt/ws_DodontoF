#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__)

require 'Autoload'

class DodontoFServer
  def initialize()
    $logger = Logger.new(AppConfig.log.path)
    $logger.level=(AppConfig.log.level)

    $refreshSaveFiles = {
      'chatMessageDataLog' => AppConfig.saveFiles['chatMessageDataLog'],
      'map' => AppConfig.saveFiles['map'],
      'characters' => AppConfig.useRecord ? 'record.json' : AppConfig.saveFiles['characters'],
      'time' => AppConfig.saveFiles['time'],
      'effects' => AppConfig.saveFiles['effects'],
      'playRoomInfo' => AppConfig.saveFiles['playRoomInfo'],
    }
  end

  def analyzeCommand(param)
    commandName = param['cmd']

    if( commandName.nil? or commandName.empty? )
      return nil
    end

    commands = {
#      'refresh' => :hasReturn,
      'login' => :hasReturn,
      'chatState' => :hasReturn
    }

    commandType = commands[commandName]
    $logger.debug({:commandType => commandType, :commandName => commandName}, "command")

    case commandType
    when :hasReturn
      return self.send( commandName, param )
    when :hasNoReturn
      self.send( commandName, param )
      return nil
    else
      throw Exception.new("\"" + commandName.untaint + "\" is invalid command")
    end
  end

  def login(param)
    return {"result" => "OK"}
  end

  def refresh(roomNumber, typeName, saveFileName)
    $logger.debug("refresh", [roomNumber, typeName, saveFileName])

    begin
      saveData = loadSaveFile(typeName, saveFileName, false, roomNumber)
      if(AppConfig.useRecord and typeName == 'characters')
        saveData["record"].reject!{|val| val[0] < $saveDatas[roomNumber]["lastRecordIndex"]}
        sendMessage(roomNumber, saveData)

        saveData["record"].each do |record|
          $saveDatas[roomNumber]["lastRecordIndex"] = record[0]+1
          case record[1]
          when "changeCharacter"
            record[2].each do |character|
              $saveDatas[roomNumber][typeName].reject!{|val| val["imgId"] == character['imgId']}
              $saveDatas[roomNumber][typeName].push(character)
            end
          when "addCharacter"
            record[2].each do |character|
              $saveDatas[roomNumber][typeName].push(character)
            end
          when "removeCharacter"
            record[2].each do |character|
              $saveDatas[roomNumber][typeName].reject!{|val| val["imgId"] == character}
            end
          end
        end
      else
        sendMessage(roomNumber, saveData)
        $saveDatas[roomNumber].merge!(saveData)
      end
    rescue => e
      print e.backtrace.join("\n")
      $logger.error(e)
    end
  end

  def chatState(param)
    $logger.debug("chatState", param)

    sender = @connections.select{|item| item[:own] == param["own"]}.pop
    if(sender)
      sender[:param][:name] = param["param"]["name"]
      sender[:param][:writingState] = param["param"]["writingState"]

      member = @connections.select{|item| item[:room] == param["room"] and item[:param][:writingState]}
      sendMessage(param["room"], {:writing => member.map{|item| item[:param][:name]}})
    end
  end

  def getMessagePackFromData(data)

    messagePack = {}

    if( data.nil? )
      $logger.debug("data is nil")
      return messagePack 
    end

    begin
      messagePack = MessagePack.unpack(data)
    rescue Exception => e
      $logger.error("getMessagePackFromData Exception rescue")
      $logger.exception(e)
    end

    return messagePack
  end

  def sendMessage(roomNo, message)
    member = @connections.select{|item| item[:room] == roomNo}
    member.each{|conn| conn[:conn].send(JSON::dump(message)) }
  end

  def getSaveTextOnFileLocked(fileName)
    empty = "{}"
    
    return empty  unless( File.exist?(fileName) )
    
    text = ''
    open(fileName, 'r') do |file|
      text = file.read
    end
    
    return empty  if( text.empty? )
    
    return text
  end

  def getObjectFromJsonString(jsonString)

    #$logger.debug(jsonString, 'getObjectFromJsonString start')
    begin
      begin
        # 文字列の変換なしでパースを行ってみる
        parsed = JsonParser.parse(jsonString)
        $logger.debug('getObjectFromJsonString parse end')

        return parsed
      rescue => e
          print e.backtrace.join("\n")
        # エスケープされた文字を戻してパースを行う
        parsedWithUnescaping = JsonParser.parse(CGI.unescape(jsonString))
        $logger.debug('getObjectFromJsonString parse with unescaping end')

        return parsedWithUnescaping
      end
    rescue => e
      print e.backtrace.join("\n")
      $logger.error(e)
      return {}
    end
  end

  def loadSaveFileForDefault(typeName, saveFileName)
    saveFileLock = FileLock.new(saveFileName)

    saveDataText = ""
    saveFileLock.lock do
      saveDataText = getSaveTextOnFileLocked(saveFileName)
    end

    saveData = getObjectFromJsonString(saveDataText)
    
    return saveData
  end

  def loadSaveFileForCharacterRecord(typeName, saveFileName, roomNumber)
    recordSaveFileName = File.join(File.dirname(saveFileName), $refreshSaveFiles[typeName])

    saveData2 = loadSaveFile(typeName, recordSaveFileName, false, roomNumber)

    saveData = loadSaveFileForDefault(typeName, saveFileName)

    if(saveData2["record"])
      saveData["lastRecordIndex"] = saveData2["record"].pop()[0]
    else
      saveData["lastRecordIndex"] = 0
    end
$logger.debug(saveData)
    return saveData
  end

  def loadSaveFileForLongChatLog(typeName, saveFileName)
    saveFileName = File.join(File.dirname(saveFileName), AppConfig.longChatLogFile)
    saveFileLock = FileLock.new(saveFileName)
    
    lines = []
    saveFileLock.lock do
      if( File.exist?(saveFileName) )
        lines = File.readlines(saveFileName)
      end
    end

    if( lines.empty? )
      return {}
    end

    chatMessageDataLog = lines.collect{|line| getObjectFromJsonString(line.chomp) }

    return {"chatMessageDataLog" => chatMessageDataLog}
  end

  def loadSaveFile(typeName, saveFileName, isFirstLoad, roomNumber)
    saveData = nil

    begin
      if(AppConfig.saveLongChatLog and
         typeName == 'chatMessageDataLog' and
         isFirstLoad)
        saveData = loadSaveFileForLongChatLog(typeName, saveFileName)
      elsif(AppConfig.useRecord and typeName == 'characters' and isFirstLoad)
        saveData = loadSaveFileForCharacterRecord(typeName, saveFileName, roomNumber)
      else
        saveData = loadSaveFileForDefault(typeName, saveFileName)
      end
    rescue => e
          print e.backtrace.join("\n")
      $logger.error(e)
      raise e
    end

    return saveData
  end

  def initSaveFiles(roomNumber, isFirstLoad)
    roomInfo = {}

    AppConfig.saveFiles.each do |saveDataKeyName, saveFileName|
      saveFileName = File.join(AppConfig.saveFileDir, "data_"+roomNumber.to_s, saveFileName)

      $logger.debug(saveDataKeyName, "saveDataKeyName")
      $logger.debug(saveFileName, "saveFileName")
      roomInfo.merge!(loadSaveFile(saveDataKeyName, saveFileName, isFirstLoad, roomNumber))
    end

    return roomInfo
  end

  def getCurrentSaveData()
    saveFiles = {}

    $logger.debug(File.realpath(AppConfig.saveFileDir))
    FileList[AppConfig.saveFileDir + "/*"].each do |saveDir|
      if(/data_(\d+)/ === File.basename(saveDir))
        roomNumber = $1.to_i
        saveFiles[roomNumber] = initSaveFiles(roomNumber, true)
      end
    end

    return saveFiles
  end

  def main()
    $server = self
    @connections = []

    $saveDatas = getCurrentSaveData()
#    $logger.debug("loaded savefiles", $saveDatas)

    begin
      @t2 = Thread.new() do
        $logger.debug("start saveData monitoring")
        FSSM.monitor AppConfig.saveFileDir, "**/*", :directories => true do
          update do |b, r, t|
            $logger.debug("file Updated", [b,r,t])
            if(:file == t)
              if(/data_(\d+)/ === File.dirname(r))
                roomNumber = $1.to_i
                if(".json" === File.extname(r) and $saveDatas[roomNumber])
                  saveDataFileName = File.basename(r)
                  saveDataType = $refreshSaveFiles.key(saveDataFileName)
                  if(saveDataType)
                    $logger.debug("playRoom Updated", [roomNumber, saveDataType])
                    $server.refresh(roomNumber, saveDataType, File.join(AppConfig.saveFileDir, "data_"+roomNumber.to_s, saveDataFileName))
                  end
                end
              end
            end
          end
          create do |b, r, t|
            if(:directory == t)
              if(/data_(\d+)/ === r)
                roomNumber = $1.to_i
                $logger.debug("playRoom Created", roomNumber)
                sleep(5);
                $saveDatas[roomNumber] = $server.initSaveFiles(roomNumber, false)
                set_glob("**/*")
              end
            end
          end
          delete do |b, r, t|
            if(:directory == t)
              if(/data_(\d+)/ === r)
                roomNumber = $1.to_i
                $logger.debug("playRoom Deleted", roomNumber)
                $saveDatas.delete(roomNumber)
              end
            end
          end
        end
        $logger.debug("end saveData monitoring")
      end

      @t = Thread.new() do
        $logger.debug("start waiting connections")
        EM::WebSocket.start({:host => AppConfig.host, :port => AppConfig.port, :secure => AppConfig.secure, :tls_options => AppConfig.tls_options}) do |ws_conn|
          sender = {
            :room => -1,
            :own => "",
            :param => {},
            :conn => ws_conn
          }

          ws_conn.onopen do
            @connections << sender
          end

          ws_conn.onbinary do |message|
            begin
              $logger.debug("original input data", message)
              param = getMessagePackFromData(message)
              $logger.debug("msgPack unpacked data", param)

              sender[:room] = param["room"]
              sender[:own] = param["own"] unless(param["own"] == "dummy")

              server = analyzeCommand(param)

              if(server != nil)
                ws_conn.send(JSON::dump(server))
              end

            rescue => e
              print e.backtrace.join("\n")
              $logger.debug(e);
            end
          end

          ws_conn.onclose do
            @connections.delete(sender)
          end
        end
      end

      while(@t.alive? && @t2.alive?)
        @t2.join()
      end
      $logger.debug("Thread End @t")
    rescue => e
      $logger.error("Server Error", e)
    ensure
      @t.kill()  if @t
      @t2.kill() if @t2
    end
  end
end

server = DodontoFServer.new()
server.main()