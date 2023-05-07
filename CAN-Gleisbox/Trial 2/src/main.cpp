#include <Arduino.h>
#include <ETH.h>
#include <ESP32CAN.h>
#include <CAN_config.h>

#define CAN_FRAME_SIZE 13        /* maximum datagram size */
#define CAN_MSG_FLAG_EXTD 0x01   /**< Extended Frame Format (29bit ID)  */
#define CAN_MSG_FLAG_SS 0x04     /**< Transmit as a Single Shot Transmission */
#define CAN_EFF_MASK 0x1FFFFFFFU /* extended frame format (EFF) */

bool done;
uint8_t M_PATTERN[] = {0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

twai_message_t Message2Send = {CAN_MSG_FLAG_EXTD | CAN_MSG_FLAG_SS, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

void prepareAndSendFrame(uint8_t *buffer)
{
  twai_message_t Message2Send;

  // CAN uses (network) big endian format
  // Maerklin TCP/UDP Format: always 13 (CAN_FRAME_SIZE) bytes
  //   byte 0 - 3  CAN ID
  //   byte 4      DLC
  //   byte 5 - 12 CAN data
  //
  Serial.print("Send: ");
  for (int i = 0; i < CAN_FRAME_SIZE; i++)
  {
    Serial.print(buffer[i], HEX);
    Serial.print(" ");
  }
  Serial.println();
  Serial.println();

  memcpy(&Message2Send.identifier, buffer, 4);
  Message2Send.identifier = ntohl(Message2Send.identifier);
  // Anzahl Datenbytes
  Message2Send.data_length_code = buffer[4];
  // Datenbytes
  if (Message2Send.data_length_code > 0)
    memcpy(&Message2Send.data, &buffer[5], Message2Send.data_length_code);
  ESP32Can.CANWriteFrame(&Message2Send);
}

void setup()
{
  Serial.begin(115200);
  done = false;
  delay(200);
  // start CAN Module
  ESP32Can.CANInit(GPIO_NUM_5, GPIO_NUM_35, ESP32CAN_SPEED_250KBPS);
}

void loop()
{
  twai_message_t MessageReceived;
  uint8_t frame[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

  // receive next CAN frame from queue
  if (ESP32Can.CANReadFrame(&MessageReceived) == ESP32CAN_OK)
  { /* CAN message received*/
    Serial.print("Rcvd: ");
    // read a packet from CAN
    MessageReceived.identifier &= CAN_EFF_MASK;
    MessageReceived.identifier = htonl(MessageReceived.identifier);
    memcpy(frame, &MessageReceived.identifier, 4);
    frame[4] = MessageReceived.data_length_code;
    memcpy(&frame[5], &MessageReceived.data, MessageReceived.data_length_code);
    for (int i = 0; i < CAN_FRAME_SIZE; i++)
    {
      Serial.print(frame[i], HEX);
      Serial.print(" ");
    }
    Serial.println();
  }
  else
  {
    if (!done)
    {
      //   byte 0 - 3  CAN ID
      //   byte 4      DLC
      //   byte 5 - 12 CAN data

      done = true;
      // M_GLEISBOX_MAGIC_START_SEQUENCE
      // damit wird die Gleisbox zum Leben erweckt
      Serial.println("M_GLEISBOX_MAGIC_START_SEQUENCE");
      memset(M_PATTERN, 0x00, sizeof(M_PATTERN));
      M_PATTERN[1] = 0x36;
      M_PATTERN[2] = 0x03;
      M_PATTERN[3] = 0x01;
      M_PATTERN[4] = 0x05;
      M_PATTERN[9] = 0x11;
      prepareAndSendFrame(M_PATTERN);

      delay(500);
      // M_PING
      Serial.println("PING");
      memset(M_PATTERN, 0x00, sizeof(M_PATTERN));
      M_PATTERN[1] = 0x30;
      M_PATTERN[2] = 0x47;
      M_PATTERN[3] = 0x11;
      prepareAndSendFrame(M_PATTERN);
    }
  }
}
