# MySQL dump 8.8                                         
#                                                        
# Host: localhost    Database: deez                      
#--------------------------------------------------------
# Server version        3.23.23-beta                     
                                                         
#                                                        
# Table structure for table 'callrecs'                   
#                                                        
                                                         
CREATE TABLE callrecs (                                  
  server varchar(32),                                    
  dso_slot tinyint(3) unsigned,                          
  dso_contr tinyint(3) unsigned,                         
  dso_chan tinyint(3) unsigned,                          
  slot tinyint(3) unsigned,                              
  port smallint(5) unsigned,                             
  call_id varchar(4),                                    
  user_id varchar(32),                                   
  ip varchar(15),                                        
  calling varchar(10),                                   
  called varchar(10),                                    
  std varchar(16),                                       
  prot varchar(32),                                      
  comp varchar(16),                                      
  init_rx mediumint(8) unsigned,                         
  init_tx mediumint(8) unsigned,                         
  rbs tinyint(3) unsigned,                               
  dpad float,                                            
  retr mediumint(8) unsigned,                            
  sq tinyint(3) unsigned,                                
  snr tinyint(3) unsigned,                               
  rx_chars int(11),                                      
  tx_chars int(11),                                      
  rx_ec int(11),                                         
  tx_ec int(11),                                         
  bad int(11),                                           
  timeon int(11),                                        
  final_state varchar(32),                               
  disc_radius varchar(32),                               
  disc_modem varchar(128),                               
  disc_local varchar(32),                                
  disc_remote varchar(32),                               
  timestamp datetime,                                    
  date date,                                             
  time time,                                             
  KEY iserver (server),                                  
  KEY iuser_id (user_id),                                
  KEY iip (ip),                                          
  KEY idate (date)                                       
);                                                       
                                                         