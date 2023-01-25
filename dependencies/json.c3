module json;

import libc;
import std::map;
import std::math;

define JsonMap = HashMap<char[], JSONType>;

enum JSONType : int 
{
	J_VALUE,
    J_OBJECT,
	J_ARRAY
}

struct JsonParser {
	uint pos;
	uint end;
	char* buffer;
	JsonMap map;
}

struct JSONItem {
	JSONType itemType;
	char* value;
}


fn JsonParser decoder(char* buffer, uint end = 0, JsonMap map = JsonMap{}) {
	if (end  == 0) {
		end = (uint)libc::strlen(buffer);
	}

	JsonParser parser = JsonParser {
		0,
		end,
		buffer,
		map
	};

	while (parser.pos != parser.end) parser.parse();
	return parser;
}

fn void JsonParser.destroy(JsonParser* self) {
	self.map.destroy();
}

private fn char JsonParser.skipSpaces(JsonParser* self) {
 	return {|
		while(true) {
			if (self.pos == self.end) {
				return 0;
				break;
			}

			char value = self.buffer[self.pos];

			switch (value) {
				case ' ':
				case '\t':
				case '\n':
				case '\r':
					self.pos += 1;
				default:
					break;
			}
			return value;
		}
	|};
}


private fn uint JsonParser.findToken(JsonParser* self, char searchToken, char skipToken = ' ') {
	uint skip = 0;
	uint endIndex = 0;
	uint startIndex = self.pos;
	uint seekPos = self.pos;

 	while (endIndex == 0) {
		if (seekPos == self.end) {
			libc::printf("Error, token end not found %c at %d \n", searchToken, seekPos);
			break;
		}

		char token = self.buffer[seekPos];
		
		if (token == skipToken && skipToken != ' ') skip += 1;
		if (token == searchToken) {
			if (skip > 0) { skip -= 1; }
			else {
				endIndex = seekPos;
				break;
			}
		};
		seekPos += 1;
	}
	return endIndex;
}

private fn void JsonParser.skipToken(JsonParser* self, char token) {
   if (self.buffer[self.pos + 1] == token) {
	   self.pos +=1;
   } else {
	  libc::printf("Token not found at %d \n", self.pos + 1);
   }
}

private fn char JsonParser.peek(JsonParser* self, int value) {
   // Try to see previous or next character if it's not overflowing.

   if (value > 0 && (self.pos + value <= self.end)) {
	   return self.buffer[self.pos + value];
   } else if (self.pos - value >= 0) {
	   return self.buffer[self.pos - math::abs(value)];
   }

   return ' ';
}





private fn void JsonParser.parse(JsonParser* self)
{	
	char[100] lastKey;
	char[100] lastValue;
	char token = self.skipSpaces();
	self.pos += 1;
	libc::printf("Token = %c %d\n", token, self.pos);
	
	switch (token) {
		case '"':
			uint index = self.findToken('"');

			if (self.peek(-1) == ':') {
				// It's a value field;
				libc::strncpy(&lastValue, self.buffer + self.pos, index - self.pos);
				libc::printf("Last value = %s \n", lastValue);
			} 
			else {
				// it's a key field
				libc::strncpy(&lastKey, self.buffer + self.pos, index - self.pos);
				libc::printf("Last key = %s \n", lastKey);
				self.pos = index;
				self.skipToken(':');
			}

		case '{':
			// Parse the Object
			uint index = self.findToken('}', '{');
			libc::printf("Object { closes at %d \n", index);
			decoder(self.buffer + self.pos, self.end - self.pos, self.map);
			self.pos = index;

			// self.map.set(lastKey, J_OBJECT);
		// case '}':
		case '[':
		// case ']':
		case ':':
			char nextToken = self.peek(-1);
			// self.pos += 1;
		case ',':

		default:
			break;
	};
}

private fn void JsonParser.parseObject(JsonParser* self)
{	
	
}