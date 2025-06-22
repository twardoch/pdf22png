CC = clang
CFLAGS = -Wall -Wextra -O2
FRAMEWORKS = -framework Foundation -framework Quartz -framework ImageIO -framework CoreGraphics -framework CoreServices
TARGET = pdf22png
SOURCE = pdf22png.m

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(FRAMEWORKS)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/

uninstall:
	rm -f /usr/local/bin/$(TARGET)

.PHONY: all clean install uninstall