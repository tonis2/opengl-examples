module json;

import libc;
import std::map;
import std::math;

define JsonMap = HashMap<char*, JSONType>;

enum JSONType : int 
{
	J_VALUE,
    J_OBJECT,
	J_ARRAY
}

struct JsonParser {
	uint pos;
	uint end;
	uint depth;
	char* buffer;
	JsonMap map;
	char[100] lastJsonKey;
}

// struct JSONItem {
// 	JSONType itemType;
// 	char* value;
// }

fn JsonParser decoder(char* buffer, uint end = 0, JsonMap map = JsonMap{}) {
	if (end  == 0) {
		end = (uint)libc::strlen(buffer);
	}

	JsonParser parser = JsonParser {
		0,
		end,
		0,
		buffer,
		map,
		{}
	};

	while (parser.pos != parser.end) parser.parse();
	return parser;
}

fn void JsonParser.destroy(JsonParser* self) {
	self.map.destroy();
}

private fn uint JsonParser.skipSpaces(JsonParser* self) {
	uint seekPos = self.pos;

	while(seekPos != self.end) {
		char value = self.buffer[seekPos];

		switch (value) {
			case ' ':
				seekPos += 1;
			case '\t':
			case '\n':
			case '\r':
				seekPos += 1;
			default:
				return seekPos;
				break;
		}
	}

	return seekPos;
}

private fn uint JsonParser.findToken(JsonParser* self, char searchToken, char skipToken = 0, uint start = self.pos + 1) {
	uint skip = 0;
	uint endIndex = 0;
	uint seekPos = start;

 	while (endIndex == 0) {
		if (seekPos == self.end) {
			libc::printf("Error, token end not found %c at %d \n", searchToken, seekPos);
			break;
		}

		char token = self.buffer[seekPos];
		
		if (token == skipToken && skipToken != 0) skip += 1;
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



private fn char JsonParser.peek(JsonParser* self, int value) {
   // Try to see previous or next character if it's not overflowing.
   if (value > 0 && (self.pos + value <= self.end)) {
	   return self.buffer[self.pos + value];
   } else if (self.pos - value >= 0) {
	   return self.buffer[self.pos - math::abs(value)];
   }
   return ' ';
}

private fn void JsonParser.parse(JsonParser* self) {
	uint tokenIndex = self.skipSpaces();
	char token = self.buffer[tokenIndex];

	switch (token) {
		case '"':
			char nextChar = self.peek(1);

			// Parse json key
			if ((nextChar != ':') && (nextChar != '}') && (nextChar != ',')) {
				uint endIndex = self.findToken('"');
				libc::memset(&self.lastJsonKey, 0);
				libc::memcpy(&self.lastJsonKey[0], self.buffer + self.pos + 1, (ulong)(endIndex - self.pos) - 1 );

				self.map.set(&self.lastJsonKey, J_OBJECT);
				libc::printf("Last key = %s \n", self.lastJsonKey[0..]);
			}
		case '{':
			// JSON goes deeper :O
			self.depth += 1;
			uint endIndex = self.findToken('}', '{');
			// libc::printf("Last key = %s \n", self.lastJsonKey[0..]);
			// libc::printf("Char %c ends at %d \n", token, endIndex);
		case ':':
				// self.map.set(&self.lastJsonKey, J_OBJECT);
		default:
	}

	self.pos = tokenIndex + 1;
}

private fn void JsonParser.parseObject(JsonParser* self)
{	
	
}



	// switch (token) {
	// 	case '"':
	// 		uint index = self.findToken('"');

	// 		if (self.peek(-1) == ':') {
	// 			// It's a value field;
	// 			libc::strncpy(&lastValue, self.buffer + self.pos, index - self.pos);
	// 			libc::printf("Last value = %s \n", lastValue);
	// 		} 
	// 		else {
	// 			// it's a key field
	// 			libc::strncpy(&lastKey, self.buffer + self.pos, index - self.pos);
	// 			libc::printf("Last key = %s \n", lastKey);
	// 			self.pos = index;
	// 			self.skipToken(':');
	// 		}

	// 	case '{':
	// 		// Parse the Object
	// 		uint index = self.findToken('}', '{');
	// 		libc::printf("Object { closes at %d \n", index);
	// 		decoder(self.buffer + self.pos, self.end - self.pos, self.map);
	// 		self.pos = index;

	// 		// self.map.set(lastKey, J_OBJECT);
	// 	// case '}':
	// 	case '[':
	// 	// case ']':
	// 	case ':':
	// 		char nextToken = self.peek(-1);
	// 		// self.pos += 1;
	// 	case ',':

	// 	default:
	// 		break;
	// };


// 	private fn void JsonParser.skipToken(JsonParser* self, char token) {
//    if (self.buffer[self.pos + 1] == token) {
// 	   self.pos +=1;
//    } else {
// 	  libc::printf("Token not found at %d \n", self.pos + 1);
//    }
// }