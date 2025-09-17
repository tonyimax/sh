
brew install doxygen &&
git clone https://github.com/gazebosim/gz-utils &&
cd gz-utils; mkdir build; cd build; cmake ../; make doc
