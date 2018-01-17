# frozen_string_literal: true

require 'spec_helper'

describe Policial::Violation do
  let(:file_content) do
    [double('line', content: 'do_something', changed?: true)]
  end
  let(:file) { build_file('application.rb', *file_content) }
  let(:line_range) { 1..1 }
  let(:message) { 'There is an error.' }
  let(:linter_name) { 'Style/ErrorDetector' }
  subject { described_class.new(file, line_range, message, linter_name) }

  describe '#filename' do
    it { expect(subject.filename).to eq 'application.rb' }
  end

  describe '#line_range' do
    let(:line_range) { 5..14 }
    it { expect(subject.line_range).to eq 5..14 }
  end

  describe '#message' do
    it { expect(subject.message).to eq 'There is an error.' }
  end

  describe '#linter' do
    it { expect(subject.linter).to eq 'Style/ErrorDetector' }
  end

  describe '#lines' do
    let(:file_content) do
      [
        double('line', content: 'if something?', changed?: false),
        double('line', content: '  say_hello', changed?: false),
        double('line', content: '  return true', changed?: false),
        double('line', content: 'end', changed?: false)
      ]
    end
    let(:line_range) { 1..2 }
    it do
      expect(subject.lines).to eq \
        ['  say_hello', '  return true']
    end
  end

  describe '#on_changed_line?' do
    context 'when at least one line in line_range has been changed' do
      let(:file_content) do
        [
          double('line', content: 'if something?', changed?: false),
          double('line', content: '  say_hello', changed?: false),
          double('line', content: '  return true', changed?: true),
          double('line', content: 'end', changed?: false)
        ]
      end
      let(:line_range) { 1..3 }
      it { expect(subject.on_changed_line?).to eq true }
    end

    context 'when no line in line_range has been changed' do
      let(:file_content) do
        [
          double('line', content: 'if something?', changed?: false),
          double('line', content: '  say_hello', changed?: false),
          double('line', content: '  return true', changed?: false),
          double('line', content: 'end', changed?: false)
        ]
      end
      let(:line_range) { 1..3 }
      it { expect(subject.on_changed_line?).to eq false }
    end
  end

  private

  def build_file(name, *lines)
    file = double(
      'file',
      filename: name,
      content: lines.map(&:content).join("\n") + "\n"
    )
    allow(file).to receive(:line_at) { |n| lines[n] }
    file
  end
end
