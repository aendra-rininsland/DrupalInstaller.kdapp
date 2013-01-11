#
# App Globals
#

kc         = KD.getSingleton "kiteController"
fc         = KD.getSingleton "finderController"
tc         = fc.treeController
{nickname} = KD.whoami().profile
appStorage = new AppStorage "drupal-installer", "1.0"

#
# App Functions
#

parseOutput = (res, err = no)->
  res = "<br><cite style='color:red'>[ERROR] #{res}</cite><br><br><br>" if err
  {output} = split
  output.setPartial res
  output.utils.wait 100, ->
    output.scrollTo
      top      : output.getScrollHeight()
      duration : 100

prepareDb = (callback)->

  parseOutput "<br>creating a database....<br>"
  kc.run
    kiteName  : "databases"
    method    : "createMysqlDatabase"
  , (err, response)=>
    if err
      parseOutput err.message, yes
      callback? err
    else
      parseOutput """
        <br>Database created:<br>
          Database User: #{response.dbUser}<br>
          Database Name: #{response.dbName}<br>
          Database Host: #{response.dbHost}<br>
          Database Pass: #{response.dbPass}<br>
        <br>
        """
      callback null, response

checkPath = (formData, callback)->

  {path, domain} = formData

  if path is "" then callback yes
  else
    kc.run "stat /Users/#{nickname}/Sites/#{domain}/website/#{path}"
    , (err, response)->
      if response
        parseOutput "Specified path isn't available, please delete it or select another path!", yes
      callback? err, response

installWordpress = (formData, dbinfo, callback)->

  {path, domain, timestamp, db} = formData

  userDir   = "/Users/#{nickname}/Sites/#{domain}/website/"
  tmpAppDir = "#{userDir}app.#{timestamp}"

  commands = [ "mkdir -p '#{tmpAppDir}'"
               "git clone --recursive --branch 7.x http://git.drupal.org/project/drupal.git " + tmpAppDir + "/drupal"
             ]
  
  if db
    # Copy the sample config
    commands.push "cp '#{tmpAppDir}/drupal/sites/default/default.settings.php' '#{tmpAppDir}/drupal/sites/default/settings.php'"
    
    # This ugly line fetchs randomly generated SALT from api.wordpress for each install and put them to the wp-config.php
    #commands.push """printf '%s\n' "g/put your unique phrase here/d" a "$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)" . w | ed -s #{tmpAppDir}/wordpress/wp-config.php"""
    
    # Put correct settings
    #commands.push "sed -i '' 's/database_name_here/#{dbinfo.dbName}/g' '#{tmpAppDir}/wordpress/wp-config.php'"
    #commands.push "sed -i '' 's/username_here/#{dbinfo.dbUser}/g' '#{tmpAppDir}/wordpress/wp-config.php'"
    #commands.push "sed -i '' 's/password_here/#{dbinfo.dbPass}/g' '#{tmpAppDir}/wordpress/wp-config.php'"
    #commands.push "sed -i '' 's/localhost/#{dbinfo.dbHost}/g' '#{tmpAppDir}/wordpress/wp-config.php'"
    
    # Make it unvisible for everyone except the user
    commands.push "chmod 700 '#{tmpAppDir}/drupal/sites/default/settings.php'"

  if path is ""
    commands.push "cp -R #{tmpAppDir}/drupal/* #{userDir}"
  else
    commands.push "mv '#{tmpAppDir}/drupal' '#{userDir}#{path}'"

  # Let remove the mess
  commands.push "rm -rf '#{tmpAppDir}'"

  # Run commands in correct order if one fails do not continue
  runInQueue = (cmds, index)=>
    command  = cmds[index]
    if cmds.length == index or not command
      parseOutput "<br>#############"
      parseOutput "<br>Drupal successfully installed to: #{userDir}#{path}"
      parseOutput "<br>#############<br>"
      parseOutput "<br><br><br>"
      appStorage.fetchValue 'blogs', (blogs)->
        blogs or= []
        blogs.push formData
        appStorage.setValue "blogs", blogs
      callback? formData
      
      # It's gonna be le{wait for it....}gendary.
      KD.utils.wait 1000, ->
        appManager.openFileWithApplication "http://#{nickname}.koding.com/#{path}/install.php", "Viewer"
      
    else
      parseOutput "$ #{command}<br/>"
      kc.run command, (err, res)=>
        if err
          parseOutput err, yes
        else
          parseOutput res + '<br/>'
          runInQueue cmds, index + 1

  runInQueue commands, 0
