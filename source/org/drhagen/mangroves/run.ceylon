import ceylon.collection {
    ArrayList
}

import ceylon.file {
    parsePath,
    File
}

shared void run() {
    // Load dictionary
    value resource = parsePath("resource/dictionary.txt").resource;

    if (is File resource) {
        value reader = resource.Reader();

        // Spin until start of dictionary ("---") is found
        while (exists word = reader.readLine(), word != "---") {}

        while (exists word = reader.readLine()) {
            if (!word.contains("'") && word.size > 1) {
                // Only add words without apostrophes greater than length 1
                dictionary.add(word);
            }
        }
    } else {
        throw Exception("Dictionary not found");
    }

    // Sort dictionary
    dictionary.sortInPlace((word1, word2) => word2.size <=> word1.size);

    // Ask user for query characters
    while (true) {
        process.write("Enter characters from which to find anagrams (empty to exit): ");
        value query_word = process.readLine();

        if (exists query_word) {
            if (query_word.size > 0) {
                print(findAnagrams(query_word.lowercased));
            } else {
                break;
            }
        } else {
            break;
        }
    }
}

ArrayList<String> dictionary = ArrayList<String> {};

{[String*]*} findAnagrams(String query_word, Integer starting_word_index = 0) =>
    dictionary
        // Ensure unique sets of found words by only continuing the search at the most recent found word
        .spanFrom(starting_word_index)
        .indexed
        .flatMap((offset_index -> dictionary_word) {
            if (query_word.size < dictionary_word.size) {
                // Terminate quickly if dictionary word is too large for query word to fit
                return {};
            }

            // A map of characters to be replaced
            variable String remaining = query_word;

            for (character1 in dictionary_word.lowercased) {
                value position = remaining.locate((character2) => character1 == character2);

                if (exists position) {
                    remaining = remaining.initial(position.key) + remaining.spanFrom(position.key + 1);
                } else {
                    // Word was not found; terminate
                    return {};
                }
            }

            // Recurse with remaining characters to see if additional words can be found
            value next_words = findAnagrams(remaining, offset_index + starting_word_index);

            if (next_words.empty) {
                // No more words were found; make a stream with just this one word
                return {[dictionary_word]};
            } else {
                // More possibilities were found; add this word to each possibility list
                return next_words.collect((words) => words.withLeading(dictionary_word));
            }
        });
