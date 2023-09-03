#/bin/sh
MQTT_MESSAGE_DELAY="2s"
DISCOVERY_PREFIX="homeassistant"
COMPONENT="sensor"
OBJECT_ID="test_dht"
OBJECT_TOPIC_STATE_NAME="${DISCOVERY_PREFIX}/${COMPONENT}/${OBJECT_ID}/state"

# load dotenv variables
source .env

# function to publish a message into MQQT broker
# $1 topic
# $2 message
publishMQTTmessage() {
	echo "Publishing message $1 on MQTT topic $2"
    mosquitto_pub \
    -h "${LAN_IP_ADDRESS}" \
    -u "${MQTT_LOGIN}" \
    -P "${MQTT_PASSWORD}" \
    -t "$1" \
    -m "$2"
    
    sleep $MQTT_MESSAGE_DELAY
}

# function to update an HA Entity state using MQTT broker
# $1 entity_id
# $2 state
updateObjectStateUsingMQTT(){
	echo "Update $1 state"
	
	topic_entity_state="${DISCOVERY_PREFIX}/${COMPONENT}/$1/state"
	publishMQTTmessage "${topic_entity_state}" "$2"
}

# function to create an HA Entity using MQTT broker
# $1 device_class
# $2 entity_id
# $3 metric_name
# $4 unit_of_measurement
# $5 value_template
createEntityUsingMQTT() {
	echo "Creating HA entity $1 using MQTT"
	topic_entity_config="${DISCOVERY_PREFIX}/${COMPONENT}/$2/config"

	publishMQTTmessage \
	"${topic_entity_config}" \
	'{"name": "DHT test", "object_id":"'$2'", "device_class": "'$1'", "state_topic": "'${OBJECT_TOPIC_STATE_NAME}'", "unit_of_measurement": "'$4'", "value_template": "{{ '$5' }}" }'
}

# function to clear an HA entity using MQTT broker
# $1 entity_id
clearEntityUsingMQTT() {
	echo "Clearing HA entity $1 using MQTT"
	topic_entity_config="${DISCOVERY_PREFIX}/${COMPONENT}/$1/config"

	publishMQTTmessage "$topic_entity_config" ''
}

# function to test entity state on HA
# $1: HA entity_id to check
# $2: expected state
testEntityStateOnHA() {
    got=`curl -s \
    -H "Authorization: Bearer ${HA_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://${DUCKDNS_DOMAIN}.duckdns.org:8123/api/states/sensor.$1" | \
    jq -r '.state'
    `
    
    if [ "$got" != "$2" ]; then
        echo "Test NOK(got=$got;expected=$2)"
        exit 1
    fi
    
    echo "Test OK(got=$got)"
}

DEVICE_CLASS="humidity"
ENTITY_ID="${OBJECT_ID}_humidity"
METRIC_NAME="Humidity"
UNIT_OF_MEASUREMENT="%"
VALUE_TEMPLATE="value_json.humidity"
createEntityUsingMQTT $DEVICE_CLASS $ENTITY_ID $METRIC_NAME $UNIT_OF_MEASUREMENT $VALUE_TEMPLATE

DEVICE_CLASS="temperature"
ENTITY_ID="${OBJECT_ID}_temperature"
METRIC_NAME="Temperature"
UNIT_OF_MEASUREMENT="°C"
VALUE_TEMPLATE="value_json.temperature"
createEntityUsingMQTT $DEVICE_CLASS $ENTITY_ID $METRIC_NAME $UNIT_OF_MEASUREMENT $VALUE_TEMPLATE

updateObjectStateUsingMQTT ${OBJECT_ID} '{ "temperature": 10.0, "humidity": 43.7 }'
testEntityStateOnHA ${OBJECT_ID}_temperature "10.0"
testEntityStateOnHA ${OBJECT_ID}_humidity "43.7"

updateObjectStateUsingMQTT ${OBJECT_ID} '{ "temperature": 24.0, "humidity": 50.0 }'
testEntityStateOnHA ${OBJECT_ID}_temperature "24.0"
testEntityStateOnHA ${OBJECT_ID}_humidity "50.0"

clearEntityUsingMQTT "${OBJECT_ID}_humidity"
clearEntityUsingMQTT "${OBJECT_ID}_temperature"

exit 0