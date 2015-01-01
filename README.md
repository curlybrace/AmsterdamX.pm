# AmsterdamX.pm

## For adding a new event:
1 Add it in templates/new_event.yaml, having fields :
  * month
  * day (monday, tuesday...)
  * daynum (day of the month, e.g. 10th, 11th...)
  * room
  * floor
  * survey_link
  * talks
    * talk1
      * speaker
      * title
      * detail
        * line1 of detail
        * line2 of detail..
2 Move text under "Upcoming events" to "Previous events", in templates/events.haml
3 Remove "Upcoming events" from templates/events.haml
4 Create a configuration file having path ~/amsterdamx_conf.yaml
5 Add these fields for email and tweet in ~/amsterdamx_conf.yaml:
  * host
  * port
  * username
  * password (if not in the conf file, you will be prompted for it later on)
  * to (comma separated list for sending multiple addresses)
  * from
  * consumer_key
  * consumer_secret
  * access_token
  * access_token_secret
5 make
