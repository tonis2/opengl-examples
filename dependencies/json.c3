module json;

import libc;

enum JSONType : int 
{
    J_OBJECT,
	J_STRING,
	J_ARRAY,
	J_NUMBER,
	J_BOOL,
	J_ERROR,
}

enum JSONTokenType : int 
{
    T_LBRACE,
	T_LBRACKET,
	T_COMMA,
	T_COLON,
	T_RBRACE,
	T_RBRACKET,
	T_STRING,
	T_NUMBER,
	T_ERROR,
	T_TRUE,
	T_FALSE,
	T_NULL,
	T_EOF,
}

struct JsonParser {
	uint pos;
	uint end;
	char* buffer;
	bool usestring;
}


fn JsonParser decoder(char* data) {
	return JsonParser {
		0,
		(uint)libc::strlen(data),
		data,
		false
	};
}

fn char JsonParser.skipSpaces(JsonParser* self) {
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

// void fn json_lexer_advance(JsonParser *parser)
// {
// 	json_skip_whitespace(parser);
// 	switch (parser->current[0])
// 	{
// 		case '\0':
// 			parser->current_token_type = T_EOF;
// 			return;
// 		case '{':
// 			parser->current_token_type = T_LBRACE;
// 			parser->current++;
// 			return;
// 		case '}':
// 			parser->current_token_type = T_RBRACE;
// 			parser->current++;
// 			return;
// 		case '[':
// 			parser->current_token_type = T_LBRACKET;
// 			parser->current++;
// 			return;
// 		case ']':
// 			parser->current_token_type = T_RBRACKET;
// 			parser->current++;
// 			return;
// 		case ':':
// 			parser->current_token_type = T_COLON;
// 			parser->current++;
// 			return;
// 		case ',':
// 			parser->current_token_type = T_COMMA;
// 			parser->current++;
// 			return;
// 		case '"':
// 			json_parse_string(parser);
// 			return;
// 		case '-':
// 		case '0':
// 		case '1':
// 		case '2':
// 		case '3':
// 		case '4':
// 		case '5':
// 		case '6':
// 		case '7':
// 		case '8':
// 		case '9':
// 			json_parse_number(parser);
// 			return;
// 		case 't':
// 			if (!json_match(parser, "true"))
// 			{
// 				json_error(parser, "Unexpected symbol, I expected maybe 'true' here.");
// 				return;
// 			}
// 			parser->current += 4;
// 			parser->current_token_type = T_TRUE;
// 			return;
// 		case 'f':
// 			if (!json_match(parser, "false"))
// 			{
// 				json_error(parser, "Unexpected symbol, I expected maybe 'false' here.");
// 				return;
// 			}
// 			parser->current += 5;
// 			parser->current_token_type = T_FALSE;
// 			return;
// 		case 'n':
// 			if (!json_match(parser, "null"))
// 			{
// 				json_error(parser, "Unexpected symbol, I expected maybe 'null' here.");
// 				return;
// 			}
// 			parser->current += 4;
// 			parser->current_token_type = T_NULL;
// 			return;
// 		default:
// 			json_error(parser, "Unexpected symbol found.");
// 			return;
// 	}
// 	UNREACHABLE
// }


// JSONObject *json_parse(JsonParser *parser)
// {
// 	if (parser->error_message) return &error;
// 	switch (parser->current_token_type)
// 	{
// 		case T_EOF:
// 			return NULL;
// 		case T_ERROR:
// 			UNREACHABLE
// 		case T_LBRACE:
// 			return json_parse_object(parser);
// 		case T_LBRACKET:
// 			return json_parse_array(parser);
// 		case T_COMMA:
// 		case T_RBRACE:
// 		case T_RBRACKET:
// 		case T_COLON:
// 			json_error(parser, "Unexpected character.");
// 			return NULL;
// 		case T_STRING:
// 		{
// 			JSONObject *obj = json_new_object(parser->allocator, J_STRING);
// 			obj->type = J_STRING;
// 			obj->str = parser->last_string;
// 			json_lexer_advance(parser);
// 			return obj;
// 		}
// 		case T_NUMBER:
// 		{
// 			JSONObject *obj = NULL;
// 			if (parser->last_number == 0) 
// 			{
// 				json_lexer_advance(parser);
// 				return &zero_val;
// 			}
// 			obj = json_new_object(parser->allocator, J_NUMBER);
// 			obj->type = J_NUMBER;
// 			obj->f = parser->last_number;
// 			json_lexer_advance(parser);
// 			return obj;
// 		}
// 		case T_TRUE:
// 			json_lexer_advance(parser);
// 			return &true_val;
// 		case T_FALSE:
// 			json_lexer_advance(parser);
// 			return &false_val;
// 		case T_NULL:
// 			json_lexer_advance(parser);
// 			return NULL;
// 	}
// 	UNREACHABLE
// }