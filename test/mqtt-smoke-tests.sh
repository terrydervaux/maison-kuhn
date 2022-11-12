#/bin/sh
LOG_MAX_DELAY="10s"

testDockerLogsPresence() {
	docker logs homeassistant --since $LOG_MAX_DELAY 2>&1| grep "$1"
	if [ $? -gt 0 ]; then
		echo "ERROR: '$1' shall be present in docker logs"
		echo "TEST: KO"
		exit 1
	fi
	echo "TEST: OK"
}

DISCOVERY_PREFIX="homeassistant"
COMPONENT="sensor"
OBJECT_ID="test_dht"
TOPIC_HUMIDITY_CONFIG="${DISCOVERY_PREFIX}/${COMPONENT}/${OBJECT_ID}_humidity/config"
TOPIC_TEMPERATURE_CONFIG="${DISCOVERY_PREFIX}/${COMPONENT}/${OBJECT_ID}_temperature/config"
TOPIC_STATE="${DISCOVERY_PREFIX}/${COMPONENT}/${OBJECT_ID}/state"

DEVICE_CLASS="humidity"
METRIC_NAME="Humidity"
echo "Configure ${OBJECT_ID} ${METRIC_NAME} using ${TOPIC_HUMIDITY_CONFIG}"
mosquitto_pub \
	-h "${DUCKDNS_DOMAIN}.duckdns.org" \
	-u ${MQTT_LOGIN} \
	-P ${MQTT_PASSWORD} \
	-t "${TOPIC_HUMIDITY_CONFIG}" \
	-m '{"name": "'${METRIC_NAME}'", "object_id":"'${OBJECT_ID}'_humidity", "device_class": "'${DEVICE_CLASS}'", "state_topic": "'${TOPIC_STATE}'", "unit_of_measurement": "%", "value_template": "{{ value_json.humidity }}" }'

DEVICE_CLASS="temperature"
METRIC_NAME="Temperature"
echo "Configure ${OBJECT_ID} ${METRIC_NAME} using ${TOPIC_TEMPERATURE_CONFIG}"
mosquitto_pub \
	-h "${DUCKDNS_DOMAIN}.duckdns.org" \
	-u ${MQTT_LOGIN} \
	-P ${MQTT_PASSWORD} \
	-t "${TOPIC_TEMPERATURE_CONFIG}" \
	-m '{"name": "'${METRIC_NAME}'", "object_id":"'${OBJECT_ID}'_temperature", "device_class": "'${DEVICE_CLASS}'", "state_topic": "'${TOPIC_STATE}'", "unit_of_measurement": "°C", "value_template": "{{ value_json.temperature }}"}'

echo "Update ${OBJECT_ID} state using ${TOPIC_STATE}"
mosquitto_pub \
	-h "${DUCKDNS_DOMAIN}.duckdns.org" \
	-u ${MQTT_LOGIN} \
	-P ${MQTT_PASSWORD} \
	-t "${TOPIC_STATE}" \
	-m '{ "temperature": 10.00, "humidity": 43.70 }'

sleep 2s

echo "Update ${OBJECT_ID} state using ${TOPIC_STATE}"
mosquitto_pub \
	-h "${DUCKDNS_DOMAIN}.duckdns.org" \
	-u ${MQTT_LOGIN} \
	-P ${MQTT_PASSWORD} \
	-t "${TOPIC_STATE}" \
	-m '{ "temperature": 24.00, "humidity": 50.00 }'

echo "Clear ${OBJECT_ID} ${METRIC_NAME} using ${TOPIC_HUMIDITY_CONFIG}"
mosquitto_pub \
	-h "${DUCKDNS_DOMAIN}.duckdns.org" \
	-u ${MQTT_LOGIN} \
	-P ${MQTT_PASSWORD} \
	-t "${TOPIC_HUMIDITY_CONFIG}" \
	-m ''

echo "Clear ${OBJECT_ID} ${METRIC_NAME} using ${TOPIC_TEMPERATURE_CONFIG}"
mosquitto_pub \
	-h "${DUCKDNS_DOMAIN}.duckdns.org" \
	-u ${MQTT_LOGIN} \
	-P ${MQTT_PASSWORD} \
	-t "${TOPIC_TEMPERATURE_CONFIG}" \
	-m ''

echo "Start tests"
testDockerLogsPresence "Found new component: sensor test_dht_humidity"
testDockerLogsPresence "Found new component: sensor test_dht_temperature"
testDockerLogsPresence "Got update for entity with hash: ('sensor', 'test_dht_humidity')"
testDockerLogsPresence "Got update for entity with hash: ('sensor', 'test_dht_temperature')"
testDockerLogsPresence "Removing component: sensor.test_dht_humidity"
testDockerLogsPresence "Removing component: sensor.test_dht_temperature"
