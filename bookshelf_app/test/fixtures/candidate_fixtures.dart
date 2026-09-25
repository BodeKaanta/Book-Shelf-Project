// GENERATED: real Google Books candidate lists for the queries the current
// query builder produces from test/fixtures/ocr_fixtures.dart, falling back
// to the relaxed/despaced retry exactly as searchBooks does when the primary
// returns nothing. Calibrates confidence offline (#83) — no network in tests.
import 'package:bookshelf_app/models/book.dart';

class CandidateFixture {
  final String name;
  final String query;
  final List<Book> candidates;
  const CandidateFixture(this.name, this.query, this.candidates);
}

Book _b(String title, String? author, String? thumb) => Book(
      id: '',
      title: title,
      author: author,
      coverUrl: Book.googleCoverUrl(thumb),
      dateAdded: DateTime(2026),
    );

final candidateFixtures = <CandidateFixture>[
  CandidateFixture('scaled_1461.png', 'SHARE THE MENTAL LOAD, FAIR PLAY', [
    _b('Fair Play', 'Eve Rodsky', 'http://books.google.com/books/content?id=DRuKDwAAQBAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('The Anti-Burnout Book', 'Emma Hepburn', 'http://books.google.com/books/content?id=UoFNEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Socio-Emotional Relationship Workbook for Couples', 'Carmen Knudson-Martin', 'http://books.google.com/books/content?id=da0vEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Marriage You Want Study Guide', 'Sheila Wray Gregoire', 'http://books.google.com/books/content?id=8uwUEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Art of Building Relationships', 'MD Amrahs', 'http://books.google.com/books/content?id=6DtrEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1453.jpg', 'Anuradha Bhagwati Unbecoming', [
    _b('Unbecoming', 'Anuradha Bhagwati', 'http://books.google.com/books/content?id=1aXODwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Twelve Feminist Lessons of War', 'Cynthia Enloe', 'http://books.google.com/books/content?id=3K_FEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Apostles of Development', 'David C. Engerman', 'http://books.google.com/books/content?id=EWtfEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Distance from Slaughter County', 'Steven Moore', 'http://books.google.com/books/content?id=k4yJEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Our Veterans', 'Suzanne Gordon', 'http://books.google.com/books/content?id=-W1tEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1454.jpg', 'ANAVY SEAL\'S UNLIKELY JOURNEY FROM Transformed REMI ADELEKE', [
    _b('Transformed', 'Remi Adeleke', 'http://books.google.com/books/content?id=EDFQDwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Transformed', 'Remi Adeleke', 'http://books.google.com/books/content?id=f2eXzQEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('I Really Needed This Today', 'Hoda Kotb', 'http://books.google.com/books/content?id=QkSwDwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1460.png', 'The Wayward Pines Trilogy BLAKE CROUCH PINES', [
    _b('Wayward', 'Blake Crouch', 'http://books.google.com/books/content?id=7GOKEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Pines', 'Blake Crouch', 'http://books.google.com/books/content?id=jjFhEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('松林異境', 'Blake Crouch', null),
    _b('The Last Town', 'Blake Crouch', 'http://books.google.com/books/content?id=4zJhEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Wayward', 'Blake Crouch', null),
  ]),
  CandidateFixture('scaled_1450.png', 'TOLKIEN LORD RINGS', [
    _b('The Fellowship of the Ring', 'John Ronald Reuel Tolkien', 'http://books.google.com/books/content?id=5sIZORTxFgMC&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('The Fellowship of the Ring (The Lord of the Rings, Book 1)', 'J. R. R. Tolkien', 'http://books.google.com/books/content?id=xFr92V2k3PIC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Fellowship Of The Ring', 'J.R.R. Tolkien', 'http://books.google.com/books/content?id=aWZzLPhY4o0C&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Fellowship of the Ring', 'John Ronald Reuel Tolkien', 'http://books.google.com/books/content?id=IGvdhaVC5QwC&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Lord of the Rings', 'Jane Chance', 'http://books.google.com/books/content?id=tRXNI15d54gC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1451.png', 'PROUEOT HAIL', [
    _b('Project Hail Mary (Movie Tie-In)', 'Andy Weir', 'http://books.google.com/books/content?id=CnSJEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Project Hail Mary', 'Andy Weir', null),
    _b('Project Hail Mary', 'Andy Weir', 'http://books.google.com/books/content?id=XT-OEAAAQBAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Storm Data', null, 'http://books.google.com/books/content?id=YBJSAQAAMAAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Politics of Geoengineering', 'Kai-Uwe Schrogl', 'http://books.google.com/books/content?id=V_C4EQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1500.heic', 'Authority Jeff VanderMeer', [
    _b('Authority', 'Jeff VanderMeer', 'http://books.google.com/books/content?id=Uy9FAwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Authority', 'Jeff VanderMeer', 'http://books.google.com/books/content?id=vNH1nQEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Authority (10th Anniversary Edition)', 'Jeff VanderMeer', 'http://books.google.com/books/content?id=BPz_EAAAQBAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Transformed States', 'Martin Halliwell', 'http://books.google.com/books/content?id=Pc0gEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Southern Reach Trilogy: Annihilation, Authority, Acceptance', 'Jeff VanderMeer', 'http://books.google.com/books/content?id=eP87DwAAQBAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1934.jpg', 'SRUEL PRUNCE HOLLI', [
    _b('The Cruel Prince', 'Holly Black', 'http://books.google.com/books/content?id=-RGkDgAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('How the King of Elfhame Learned to Hate Stories', 'Holly Black', null),
    _b('The Lost Sisters (A Novella of Elfhame)', 'Holly Black', 'http://books.google.com/books/content?id=2wlxDwAAQBAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('The Lost Sisters', 'Holly Black', null),
    _b('The Queen of Nothing', 'Holly Black', 'http://books.google.com/books/content?id=7LaMDwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1452.jpg', 'NoTEB OOK Nicholas Sparks', [
    _b('The Notebook', 'Nicholas Sparks', null),
    _b('The Notebook', 'Nicholas Sparks', null),
    _b('The Notebook', 'Editorial Editorial Universe', 'http://books.google.com/books/content?id=hhDwsgEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('The Notebook', 'Nicholas Sparks', 'http://books.google.com/books/content?id=eXhPPgAACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('The Notebook', 'Nicholas Sparks', 'http://books.google.com/books/content?id=mzFyBAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1499.heic', 'GARDENER?S GUIDE BOTANYS', [
    _b('Gardener\'s Guide to Botany', 'Paul R Wonning', 'http://books.google.com/books/content?id=C85QyAEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Gardener\'s Guide to Botany', 'Paul R. Wonning', null),
    _b('Gardener?s Guide to Botany', 'Paul R. Wonning', 'http://books.google.com/books/content?id=1DQcDQEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Gardener’s Guide to Botany', 'Paul R. Wonning', 'http://books.google.com/books/content?id=_hKlDwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Gardener\'s Guide to the Plant Root', 'Paul Wonning', 'http://books.google.com/books/content?id=3Hu4DAEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1455.heic', 'ALDO RosSI DRAWINGS AND PAINTINGS AND GIOVANNI BERTOLOTTO', [
    _b('Aldo Rossi', 'Aldo Rossi', 'http://books.google.com/books/content?id=P9NeOesgDtgC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Art of Architectural Drawing', 'Thomas Wells Schaller', 'http://books.google.com/books/content?id=R4dwBnjpzfcC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Scenographic Design Drawing', 'Sue Field', 'http://books.google.com/books/content?id=n10IEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Encyclopedia of Twentieth Century Architecture', 'R. Stephen Sennott', 'http://books.google.com/books/content?id=O9jeQtQ5CKgC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Modern Architecture and the Mediterranean', 'Jean-Francois Lejeune', 'http://books.google.com/books/content?id=fFRdBwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1456.heic', 'THE HOUSE OF A SAGA DF THE RUSSIAN', [
    _b('Shredding the Map', 'Edith Clowes', 'http://books.google.com/books/content?id=7CYeEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Great Restoration: Post-Communist Transformations from the Viewpoint of Comparative Historical Sociology of Restorations', 'Zenonas Norkus', 'http://books.google.com/books/content?id=ANT7EAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Evolution of Naval Mine Warfare', 'Jacob A. Mazurek', 'http://books.google.com/books/content?id=SVTXEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Breaking The Covenant', 'Boris Draznin', 'http://books.google.com/books/content?id=hUfXEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Surface Water Records of Georgia', null, 'http://books.google.com/books/content?id=R-qyq6-7RTcC&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1457.heic', 'CASTLE JOHN GOODALL', [
    _b('The Castle', 'John Goodall', 'http://books.google.com/books/content?id=c4xhEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The English Castle, 1066-1650', 'John Goodall', 'http://books.google.com/books/content?id=n_6PHAAACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Greater Medieval Houses of England and Wales, 1300–1500: Volume 3, Southern England', 'Anthony Emery', 'http://books.google.com/books/content?id=g7EXvaDEYioC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Castle at War in Medieval England and Wales', 'Dan Spencer', 'http://books.google.com/books/content?id=CK2IDwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Creepy Castle', 'John S. Goodall', 'http://books.google.com/books/content?id=SCJEPgAACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1458.heic', 'INVISIBLE CITIES ITALO CALVINO', [
    _b('Invisible Cities', 'Italo Calvino', 'http://books.google.com/books/content?id=Pn8d9riSL6UC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Invisible Cities', 'Italo Calvino', 'http://books.google.com/books/content?id=ITXpzgEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Invisible Cities', 'Italo Calvino', null),
    _b('Invisible Cities', 'Italo Calvino', null),
    _b('Invisible Cities', 'Emile Harrak', null),
  ]),
  CandidateFixture('scaled_1459.heic', 'THE DREAM HOTEL LAILA LALAMI', [
    _b('The Dream Hotel: A Read with Jenna Pick', 'Laila Lalami', 'http://books.google.com/books/content?id=7qzFEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Dream Hotel', 'Laila Lalami', 'http://books.google.com/books/content?id=qy1EEQAAQBAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('The Dream Hotel: A Read with Jenna Pick', 'Laila Lalami', 'http://books.google.com/books/content?id=UGgwEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Last of Earth', 'Deepa Anappara', 'http://books.google.com/books/content?id=7ABzEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Guardians of the Republic: Essays on the Constitution, Justice, and the Future of Indian Democracy', 'Ashwani Kumar', 'http://books.google.com/books/content?id=ygXNEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1498.heic', 'WHEN BECKY,CHAMBERS A Psalm for the Wild-Built', [
    _b('A Psalm for the Wild-Built', 'Becky Chambers', 'http://books.google.com/books/content?id=XgT6DwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Monk and Robot', 'Becky Chambers', 'http://books.google.com/books/content?id=8h8ZEQAAQBAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('The Climate Imaginary', 'Jose Ulloa Melara', 'http://books.google.com/books/content?id=_AnwEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Saving Utopia', 'Joe P. L. Davidson', 'http://books.google.com/books/content?id=oiBzEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Climate Fiction Reader', 'April Teague', 'http://books.google.com/books/content?id=tNb4EQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1495.heic', 'T. KINGFISHER HOUSE WITH', [
    _b('A House With Good Bones', 'T. Kingfisher', 'http://books.google.com/books/content?id=Km9pEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('What Moves the Dead', 'T. Kingfisher', 'http://books.google.com/books/content?id=7CtBEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('House documents', null, 'http://books.google.com/books/content?id=XfZoe4HqY4gC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Hunts\' universal yacht list', null, 'http://books.google.com/books/content?id=0F4RjyA-oDoC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Feral and Hysterical', 'Sadie Hartmann', 'http://books.google.com/books/content?id=vcQaEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1494.heic', 'Kate Quinn YEAR RAVENS', [
    _b('A Year of Ravens', 'Kate Quinn', 'http://books.google.com/books/content?id=63SmEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Becoming Madam Secretary', 'Stephanie Dray', 'http://books.google.com/books/content?id=B7AyEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Women of Chateau Lafayette', 'Stephanie Dray', 'http://books.google.com/books/content?id=SURfEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Tacfarinas: An African Rebel Against Rome', 'Joanne Ball', 'http://books.google.com/books/content?id=vsCpEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Britain and Boudicca', 'Gunivortus Goos', 'http://books.google.com/books/content?id=-rhSEQAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1496.heic', 'Overstory Richard PoWers', [
    _b('The Overstory', 'Richard Powers', 'http://books.google.com/books/content?id=_zQsDwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Bewilderment', 'Richard Powers', 'http://books.google.com/books/content?id=LfkQEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Overstory', 'Richard Powers', 'http://books.google.com/books/content?id=xDksDwAAQBAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Extended Summary - The Overstory - Based On The Book By Richard Powers', 'Mentors Library', 'http://books.google.com/books/content?id=BzPoEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('The Overstory', 'Richard Powers', 'http://books.google.com/books/content?id=GzXawAEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
  ]),
  CandidateFixture('scaled_1497.heic', 'AVELL Cheerf Retuse', [
    _b('You\'ve Got Spirit!', 'Sara R. Hunt', 'http://books.google.com/books/content?id=tWRXBAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Make Some Noise', 'Rebecca Rissman', 'http://books.google.com/books/content?id=TyoXCgAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    _b('Cheer Skills and Drills', 'Marcia Amidon Lusted', 'http://books.google.com/books/content?id=INc0jgEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Cheerleading Skills', 'Tracy Nelson Maurer', 'http://books.google.com/books/content?id=UEjnAAAACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
    _b('Hashtag #Cheer Status', 'Jala Randolph', 'http://books.google.com/books/content?id=0e1moAEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api'),
  ]),
];
