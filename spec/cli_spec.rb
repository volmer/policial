# frozen_string_literal: true

require 'spec_helper'

describe Policial::CLI do
  subject { described_class.new }

  before(:each) { ENV['GITHUB_ACCESS_TOKEN'] = '1234' }
  after(:each) { ENV['GITHUB_ACCESS_TOKEN'] = nil }

  describe '#investigate' do
    context 'when GITHUB_ACCESS_TOKEN environment variable is not set' do
      it 'aborts with exit status code 1' do
        ENV['GITHUB_ACCESS_TOKEN'] = nil

        output = capture(:stderr) {
          expect(lambda { subject.investigate('volmer/policial', 1) }).to exit_with_code(1)
        }

        expect(output).to eq("You must set the GITHUB_ACCESS_TOKEN environment variable.\n")
      end
    end

    context 'when repo is not specified' do
      context 'within a git repository folder' do
        context 'that has no GitHub remote' do
          it 'aborts with exit status code 1' do
            allow(Open3).to receive(:popen3).with('/usr/bin/env git remote -v') { [StringIO.new, StringIO.new("origin git@bitbucket.org:Yourname/firstdemotry.git (fetch)\norigin git@bitbucket.org:Yourname/firstdemotry.git (push)\n"), StringIO.new] }

            output = capture(:stderr) {
              expect(lambda { subject.investigate(nil, 1) }).to exit_with_code(1)
            }

            expect(output).to eq("Could not detect GitHub repository for #{ENV['PWD']}\n")
          end
        end

        context 'that has a GitHub remote' do
          context 'with non-existant pull request' do
            it 'aborts with exit status code 1' do
              allow(Open3).to receive(:popen3).with('/usr/bin/env git remote -v') { [StringIO.new, StringIO.new("origin git@github.com:volmer/policial.git (fetch)\norigin git@github.com:volmer/policial.git (push)\n"), StringIO.new] }

              stub_non_existant_pull_request_request('volmer/policial', 0)

              capture(:stderr) {
                expect(lambda { subject.investigate(nil, 0) }).to exit_with_code(1)
              }
            end
          end
        end
      end

      context 'within a non-git repository folder' do
        it 'aborts with exit status code 1' do
          allow(Open3).to receive(:popen3).with('/usr/bin/env git remote -v') { [StringIO.new, StringIO.new, StringIO.new("fatal: Not a git repository (or any of the parent directories): .git\n")] }

          output = capture(:stderr) {
            expect(lambda { subject.investigate(nil, 1) }).to exit_with_code(1)
          }

          expect(output).to eq("fatal: Not a git repository (or any of the parent directories): .git\n")
        end
      end
    end

    context 'when repo is specified' do
      context 'when pull_request does not exist' do
        it 'aborts with exit status code 1' do
          stub_non_existant_pull_request_request('volmer/policial', 0)

          output = capture(:stderr) {
            expect(lambda { subject.investigate('volmer/policial', 0) }).to exit_with_code(1)
          }

          expect(output).to eq("Could not find pull request #0 for repository volmer/policial.\n")
        end
      end

      context 'when pull request exists' do
        before do
          stub_pull_request_request_with_fixture('volmer/policial', 3, fixture: 'pull_request_volmer_policial_3')
          stub_pull_request_files_request('etiennebarrie/policial', 3)
          stub_contents_request_with_fixture(
            'etiennebarrie/policial',
            sha: 'b87e46080feb3c788f8fee95bbbbef190560a98a',
            file: '.rubocop.yml',
            fixture: 'config_contents.json'
          )
        end

        context 'has violations' do
          it 'aborts with exit status code 1' do
            stub_contents_request_with_fixture(
              'etiennebarrie/policial',
              sha: 'b87e46080feb3c788f8fee95bbbbef190560a98a',
              file: 'config/unicorn.rb',
              fixture: 'contents_with_violations.json'
            )

            output = capture(:stdout) {
              expect(lambda { subject.investigate('volmer/policial', 3) }).to exit_with_code(1)
            }

            expect(output).to eq("config/unicorn.rb:1 - Omit the parentheses in defs when the method doesn't accept any arguments.\nconfig/unicorn.rb:1 - Trailing whitespace detected.\n")
          end
        end

        context 'has no violations' do
          it 'aborts with exit status code 0' do
            stub_contents_request_with_fixture(
              'etiennebarrie/policial',
              sha: 'b87e46080feb3c788f8fee95bbbbef190560a98a',
              file: 'config/unicorn.rb',
              fixture: 'contents.json'
            )

            output = capture(:stdout) {
              expect(lambda { subject.investigate('volmer/policial', 3) }).to exit_with_code(0)
            }

            expect(output).to eq("No violations found.\n")
          end
        end
      end
    end
  end
end
